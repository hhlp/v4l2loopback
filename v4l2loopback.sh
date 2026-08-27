#!/usr/bin/env bash
# ============================================================
# Fedora v4l2loopback Management Script
# Secure Boot Compatible
#
# Commands:
#   genkey
#   needs-rebuild
#   rebuild
#   reinstall
#   uninstall
#   enable-systemd
#   disable-systemd
#   help
#
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

REPO_URL="https://github.com/v4l2loopback/v4l2loopback.git"
REPO_DIR="/usr/src/v4l2loopback"

MODULE_NAME="v4l2loopback"
MODULE_SUBDIR="updates"

MODULE_OPTS=(
    "devices=1"
    "video_nr=10"
    "card_label=VirtualCam"
    "exclusive_caps=1"
)

KEY_DIR="/var/lib/shim-signed/mok"
KEY_PRIV="$KEY_DIR/v4l.key"
KEY_PEM="$KEY_DIR/v4l.der"

CONFIG_MODPROBE="/etc/modprobe.d/${MODULE_NAME}.conf"
CONFIG_AUTOLOAD="/etc/modules-load.d/${MODULE_NAME}.conf"

CN_MATCH="CN=V4L2Loopback Module Signing"

PROGRAM_PATH="/usr/bin/v4l2loopback"

SYSTEMD_SERVICE_NAME="v4l2loopback-rebuild.service"
SYSTEMD_SERVICE="/etc/systemd/system/$SYSTEMD_SERVICE_NAME"

# ============================================================
# GET NEWEST INSTALLED KERNEL-DEVEL
# ============================================================

get_latest_kernel() {
    local latest_kernel

    latest_kernel="$(
        rpm -q kernel-devel \
            --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' 2>/dev/null |
            sort -V |
            tail -n 1
    )"

    if [[ -z "$latest_kernel" ]]; then
        echo "❌ No kernel-devel packages found." >&2
        echo >&2
        echo "Install kernel-devel first:" >&2
        echo >&2
        echo "   sudo dnf install -y kernel-devel" >&2
        return 1
    fi

    printf '%s\n' "$latest_kernel"
}

# ============================================================
# GET EXPECTED MODULE PATH
# ============================================================

get_module_path() {
    local kver

    kver="$(get_latest_kernel)"

    printf '/lib/modules/%s/%s/%s.ko\n' \
        "$kver" \
        "$MODULE_SUBDIR" \
        "$MODULE_NAME"
}

# ============================================================
# NEEDS REBUILD
#
# Exit codes:
#
#   0 -> module is missing -> rebuild required
#   1 -> module exists     -> nothing required
#
# This behavior is intentionally designed for systemd
# ExecCondition=.
# ============================================================

needs_rebuild() {
    local kver
    local module_path

    kver="$(get_latest_kernel)"
    module_path="/lib/modules/$kver/$MODULE_SUBDIR/${MODULE_NAME}.ko"

    echo "🔎 Checking newest installed kernel:"
    echo "   $kver"
    echo

    echo "🔎 Checking module:"
    echo "   $module_path"
    echo

    if [[ -f "$module_path" ]]; then
        echo "✅ Module already exists."
        echo "ℹ️ Nothing to rebuild."

        return 1
    fi

    echo "⚠️ Module does not exist."
    echo "🔨 Rebuild required."

    return 0
}

# ============================================================
# GENERATE SIGNING KEY
# ============================================================

gen_signing_key() {
    echo "=== 🔑 Generating Secure Boot signing key ==="
    echo

    sudo mkdir -p "$KEY_DIR"

    if [[ -f "$KEY_PRIV" || -f "$KEY_PEM" ]]; then
        echo "⚠️ Signing key already exists:"
        echo "   $KEY_DIR"
        echo

        sudo ls -l "$KEY_DIR"/v4l.* 2>/dev/null || true
    else
        sudo openssl req \
            -new \
            -x509 \
            -newkey rsa:2048 \
            -keyout "$KEY_PRIV" \
            -outform DER \
            -out "$KEY_PEM" \
            -nodes \
            -days 36500 \
            -subj "/CN=V4L2Loopback Module Signing/"

        sudo chmod 600 "$KEY_PRIV"

        echo
        echo "✅ Signing key generated:"
        sudo ls -l "$KEY_DIR"/v4l.*
    fi

    echo
    echo "🔐 Importing certificate into MOK..."
    echo
    echo "You will be asked to create a temporary password."
    echo "This password is required once in the MOK Manager"
    echo "screen during the next reboot."
    echo

    sudo mokutil --import "$KEY_PEM"

    echo
    echo "✅ MOK enrollment scheduled."
    echo
    echo "Check pending enrollment:"
    echo
    echo "   mokutil --list-new"
    echo
    echo "Then reboot:"
    echo
    echo "   sudo reboot"
}

# ============================================================
# WRITE CONFIGURATION
# ============================================================

write_configuration() {
    echo "📝 Writing module configuration..."

    printf 'options %s %s\n' \
        "$MODULE_NAME" \
        "${MODULE_OPTS[*]}" |
        sudo tee "$CONFIG_MODPROBE" >/dev/null

    printf '%s\n' "$MODULE_NAME" |
        sudo tee "$CONFIG_AUTOLOAD" >/dev/null

    echo
    echo "✅ Configuration written:"
    echo "   $CONFIG_MODPROBE"
    echo "   $CONFIG_AUTOLOAD"
}

# ============================================================
# REBUILD MODULE
# ============================================================

rebuild_module() {
    local kver
    local kernel_src
    local sign_file
    local install_path
    local installed_module

    echo "=== 🧰 v4l2loopback rebuild ==="
    echo

    kver="$(get_latest_kernel)"

    kernel_src="/usr/src/kernels/$kver"
    sign_file="$kernel_src/scripts/sign-file"
    install_path="/lib/modules/$kver/$MODULE_SUBDIR"
    installed_module="$install_path/${MODULE_NAME}.ko"

    echo "🐧 Latest installed kernel-devel:"
    echo "   $kver"
    echo

    echo "🔎 Checking existing module:"
    echo "   $installed_module"
    echo

    if [[ -f "$installed_module" ]]; then
        echo "✅ Module already exists."
        echo
        echo "📦 Existing module:"
        echo "   $installed_module"
        echo
        echo "ℹ️ Nothing to do."

        return 0
    fi

    echo "⚠️ Module does not exist."
    echo "→ It will be compiled, signed and installed."
    echo

    # --------------------------------------------------------
    # Check source repository
    # --------------------------------------------------------

    if [[ ! -d "$REPO_DIR" ]]; then
        echo "❌ Source repository not found:"
        echo "   $REPO_DIR"
        echo
        echo "Clone it with:"
        echo
        echo "   sudo git clone $REPO_URL $REPO_DIR"

        return 1
    fi

    # --------------------------------------------------------
    # Check signing keys
    # --------------------------------------------------------

    if [[ ! -f "$KEY_PRIV" || ! -f "$KEY_PEM" ]]; then
        echo "❌ Signing keys not found:"
        echo
        echo "   $KEY_PRIV"
        echo "   $KEY_PEM"
        echo
        echo "Generate them first:"
        echo
        echo "   sudo $0 genkey"

        return 1
    fi

    # --------------------------------------------------------
    # Check kernel headers
    # --------------------------------------------------------

    if [[ ! -d "$kernel_src" ]]; then
        echo "❌ Kernel development directory not found:"
        echo "   $kernel_src"

        return 1
    fi

    if [[ ! -x "$sign_file" ]]; then
        echo "❌ Kernel signing utility not found:"
        echo "   $sign_file"

        return 1
    fi

    # --------------------------------------------------------
    # Build
    # --------------------------------------------------------

    cd "$REPO_DIR"

    echo "🧹 Cleaning previous build..."

    make clean

    echo
    echo "🔨 Compiling for:"
    echo "   $kver"
    echo

    make KERNELRELEASE="$kver"

    if [[ ! -f "${MODULE_NAME}.ko" ]]; then
        echo
        echo "❌ Compilation failed."
        echo "Expected:"
        echo
        echo "   $REPO_DIR/${MODULE_NAME}.ko"

        return 1
    fi

    echo
    echo "✅ Module compiled."

    # --------------------------------------------------------
    # Sign
    # --------------------------------------------------------

    echo
    echo "🔐 Signing module..."

    sudo "$sign_file" \
        sha256 \
        "$KEY_PRIV" \
        "$KEY_PEM" \
        "${MODULE_NAME}.ko"

    echo "✅ Module signed."

    # --------------------------------------------------------
    # Install
    # --------------------------------------------------------

    echo
    echo "📦 Installing module:"
    echo "   $installed_module"

    sudo install \
        -D \
        -m 644 \
        "${MODULE_NAME}.ko" \
        "$installed_module"

    # --------------------------------------------------------
    # depmod
    # --------------------------------------------------------

    echo
    echo "🔄 Updating module dependencies..."

    sudo depmod -a "$kver"

    echo
    echo "✅ Module installed successfully."

    # --------------------------------------------------------
    # Load if kernel is running
    # --------------------------------------------------------

    if [[ "$kver" == "$(uname -r)" ]]; then
        echo
        echo "🔌 Module was built for the running kernel."
        echo "Reloading..."

        sudo modprobe -r "$MODULE_NAME" 2>/dev/null || true

        sudo modprobe \
            "$MODULE_NAME" \
            "${MODULE_OPTS[@]}"

        echo
        echo "✅ Module loaded."

        echo
        echo "📋 Module information:"

        modinfo "$MODULE_NAME" |
            grep -E \
                '^(filename|version|signer|sig_key|sig_hashalgo):' ||
            true
    else
        echo
        echo "ℹ️ Module installed for a newer kernel."
        echo
        echo "Running kernel:"
        echo "   $(uname -r)"
        echo
        echo "Newest installed kernel:"
        echo "   $kver"
        echo
        echo "Reboot to use it:"
        echo
        echo "   sudo reboot"
    fi
}

# ============================================================
# ENABLE SYSTEMD
# ============================================================

enable_systemd() {
    echo "=== ⚙️ Enabling systemd v4l2loopback check ==="
    echo

    # ========================================================
    # 1. CHECK / CREATE SYSTEMD SERVICE FILE
    # ========================================================

    if [[ -f "$SYSTEMD_SERVICE" ]]; then
        echo "ℹ️ systemd service already exists:"
        echo "   $SYSTEMD_SERVICE"
        echo
        echo "ℹ️ Existing service file will NOT be overwritten."
        echo
    else
        echo "📝 systemd service does not exist."
        echo "→ Creating:"
        echo "   $SYSTEMD_SERVICE"
        echo

        sudo tee "$SYSTEMD_SERVICE" >/dev/null <<EOF
[Unit]
Description=Ensure v4l2loopback exists for newest installed kernel
Documentation=https://github.com/hhlp/v4l2loopback
After=local-fs.target
ConditionPathExists=$PROGRAM_PATH

[Service]
Type=oneshot

ExecCondition=$PROGRAM_PATH needs-rebuild
ExecStart=$PROGRAM_PATH rebuild

[Install]
WantedBy=multi-user.target
EOF

        echo "✅ systemd service created:"
        echo "   $SYSTEMD_SERVICE"
        echo

        echo "🔄 Reloading systemd configuration..."

        sudo systemctl daemon-reload

        echo "✅ systemd configuration reloaded."
        echo
    fi

    # ========================================================
    # 2. CHECK WHETHER SERVICE IS ENABLED
    # ========================================================

    if systemctl is-enabled \
        "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1
    then
        echo "✅ systemd service is already enabled:"
        echo "   $SYSTEMD_SERVICE_NAME"
        echo
        echo "ℹ️ Nothing to enable."
    else
        echo "⚙️ systemd service exists but is not enabled."
        echo "→ Enabling:"
        echo "   $SYSTEMD_SERVICE_NAME"
        echo

        sudo systemctl enable "$SYSTEMD_SERVICE_NAME"

        echo
        echo "✅ systemd service enabled."
    fi

    # ========================================================
    # 3. RUN THE CHECK NOW
    # ========================================================

    echo
    echo "🔎 Running v4l2loopback systemd check now..."
    echo

    sudo systemctl start "$SYSTEMD_SERVICE_NAME"

    echo
    echo "✅ systemd check completed."

    # ========================================================
    # 4. INFORMATION
    # ========================================================

    echo
    echo "------------------------------------------------------------"
    echo "systemd service:"
    echo
    echo "   $SYSTEMD_SERVICE_NAME"
    echo
    echo "systemd unit:"
    echo
    echo "   $SYSTEMD_SERVICE"
    echo
    echo "At boot the service checks:"
    echo
    echo "   /lib/modules/<latest-kernel>/updates/${MODULE_NAME}.ko"
    echo
    echo "If the module exists:"
    echo
    echo "   → ExecCondition returns 1"
    echo "   → rebuild is skipped"
    echo
    echo "If the module is missing:"
    echo
    echo "   → ExecCondition returns 0"
    echo "   → rebuild is executed"
    echo
    echo "Check service status:"
    echo
    echo "   systemctl status $SYSTEMD_SERVICE_NAME"
    echo
    echo "Check boot logs:"
    echo
    echo "   journalctl -b -u $SYSTEMD_SERVICE_NAME"
}

# ============================================================
# DISABLE SYSTEMD
# ============================================================

disable_systemd() {
    local changed=false

    echo "=== ⚙️ Disabling systemd v4l2loopback check ==="
    echo

    # ========================================================
    # 1. CHECK WHETHER SERVICE IS ENABLED
    # ========================================================

    if systemctl is-enabled \
        "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1
    then
        echo "⚙️ systemd service is enabled:"
        echo "   $SYSTEMD_SERVICE_NAME"
        echo
        echo "→ Disabling service..."

        sudo systemctl disable "$SYSTEMD_SERVICE_NAME"

        echo
        echo "✅ systemd service disabled."

        changed=true
    else
        echo "ℹ️ systemd service is already disabled:"
        echo "   $SYSTEMD_SERVICE_NAME"
        echo
        echo "ℹ️ Nothing to disable."
    fi

    # ========================================================
    # 2. CHECK WHETHER SERVICE FILE EXISTS
    # ========================================================

    echo

    if [[ -f "$SYSTEMD_SERVICE" ]]; then
        echo "🗑 systemd service file exists:"
        echo "   $SYSTEMD_SERVICE"
        echo
        echo "→ Removing service file..."

        sudo rm -f "$SYSTEMD_SERVICE"

        echo
        echo "✅ systemd service file removed."

        changed=true
    else
        echo "ℹ️ systemd service file does not exist:"
        echo "   $SYSTEMD_SERVICE"
        echo
        echo "ℹ️ Nothing to remove."
    fi

    # ========================================================
    # 3. RELOAD SYSTEMD ONLY IF SOMETHING CHANGED
    # ========================================================

    echo

    if [[ "$changed" == true ]]; then
        echo "🔄 Reloading systemd configuration..."

        sudo systemctl daemon-reload

        echo "✅ systemd configuration reloaded."
    else
        echo "ℹ️ No systemd changes were required."
    fi

    # ========================================================
    # 4. CLEAR FAILED STATE IF PRESENT
    # ========================================================

    if systemctl is-failed \
        "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1
    then
        echo
        echo "⚠️ Service has a failed state."
        echo "→ Clearing failed state..."

        sudo systemctl reset-failed "$SYSTEMD_SERVICE_NAME"

        echo "✅ Failed state cleared."
    fi

    # ========================================================
    # 5. FINAL STATUS
    # ========================================================

    echo
    echo "------------------------------------------------------------"
    echo "systemd integration status:"
    echo
    echo "   Service:"
    echo "      $SYSTEMD_SERVICE_NAME"
    echo
    echo "   Unit file:"
    echo "      $SYSTEMD_SERVICE"
    echo
    echo "✅ systemd integration is disabled."
}

# ============================================================
# UNINSTALL MODULE
# ============================================================

uninstall_module() {
    local der_to_delete=""
    local tmp_dir=""
    local yn
    local modpath
    local kdir

    echo "=== 🧼 Uninstalling $MODULE_NAME ==="
    echo

    # --------------------------------------------------------
    # Unload
    # --------------------------------------------------------

    if lsmod | grep -q "^${MODULE_NAME}"; then
        echo "🔌 Unloading module..."

        sudo modprobe -r "$MODULE_NAME" || true
    else
        echo "ℹ️ Module is not currently loaded."
    fi

    # --------------------------------------------------------
    # MOK certificate
    # --------------------------------------------------------

    if command -v mokutil >/dev/null 2>&1; then
        echo
        echo "🔐 Checking MOK certificate..."

        if [[ -f "$KEY_PEM" ]]; then
            der_to_delete="$KEY_PEM"
        else
            tmp_dir="$(mktemp -d)"

            pushd "$tmp_dir" >/dev/null

            sudo mokutil --export >/dev/null 2>&1 || true

            for f in MOK-*.der; do
                [[ -f "$f" ]] || continue

                if openssl x509 \
                    -inform der \
                    -in "$f" \
                    -noout \
                    -subject 2>/dev/null |
                    grep -q "$CN_MATCH"
                then
                    der_to_delete="$tmp_dir/$f"
                    break
                fi
            done

            popd >/dev/null
        fi

        if [[ -n "$der_to_delete" && -f "$der_to_delete" ]]; then
            echo
            echo "🗝 MOK certificate found:"
            echo "   $der_to_delete"
            echo

            read -rp \
                "Stage MOK certificate deletion? [y/N] " \
                yn

            if [[ "$yn" =~ ^[Yy]$ ]]; then
                sudo mokutil --delete "$der_to_delete" || true

                echo
                sudo mokutil --list-delete || true

                echo
                echo "👉 Reboot and confirm 'Delete MOK'"
                echo "   in the MOK Manager screen."
            else
                echo "ℹ️ MOK certificate preserved."
            fi
        else
            echo "ℹ️ MOK certificate not found automatically."
        fi

        if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
            rm -rf "$tmp_dir"
        fi
    fi

    # --------------------------------------------------------
    # Remove modules
    # --------------------------------------------------------

    echo
    echo "🗑 Removing installed modules..."

    for kdir in /lib/modules/*; do
        [[ -d "$kdir" ]] || continue

        modpath="$kdir/$MODULE_SUBDIR/${MODULE_NAME}.ko"

        if [[ -f "$modpath" ]]; then
            echo "   → $modpath"

            sudo rm -f "$modpath"

            sudo depmod -a "$(basename "$kdir")" || true
        fi
    done

    # --------------------------------------------------------
    # Remove configuration
    # --------------------------------------------------------

    echo
    echo "🗑 Removing configuration..."

    sudo rm -f \
        "$CONFIG_MODPROBE" \
        "$CONFIG_AUTOLOAD"

    # --------------------------------------------------------
    # Source repository
    # --------------------------------------------------------

    if [[ -d "$REPO_DIR" ]]; then
        echo

        read -rp \
            "Remove source repository at $REPO_DIR? [y/N] " \
            yn

        if [[ "$yn" =~ ^[Yy]$ ]]; then
            sudo rm -rf "$REPO_DIR"

            echo "✅ Source repository removed."
        else
            echo "ℹ️ Source repository preserved."
        fi
    fi

    # --------------------------------------------------------
    # Signing keys
    # --------------------------------------------------------

    if [[ -f "$KEY_PRIV" || -f "$KEY_PEM" ]]; then
        echo

        read -rp \
            "Remove local signing keys in $KEY_DIR? [y/N] " \
            yn

        if [[ "$yn" =~ ^[Yy]$ ]]; then
            sudo rm -f \
                "$KEY_PRIV" \
                "$KEY_PEM"

            echo "✅ Signing keys removed."
        else
            echo "ℹ️ Signing keys preserved."
        fi
    fi

    echo
    echo "✅ Uninstall complete."
}

# ============================================================
# REINSTALL MODULE
# ============================================================

reinstall_module() {
    echo "=== 🔄 Reinstalling $MODULE_NAME ==="
    echo

    uninstall_module

    echo
    echo "📥 Preparing source repository..."

    if [[ -d "$REPO_DIR" ]]; then
        echo "ℹ️ Existing repository preserved:"
        echo "   $REPO_DIR"
    else
        sudo git clone \
            --depth=1 \
            "$REPO_URL" \
            "$REPO_DIR"

        echo
        echo "✅ Repository cloned."
    fi

    echo
    write_configuration

    echo
    echo "🛠 Regenerating initramfs..."

    sudo dracut -f

    echo
    rebuild_module
}

# ============================================================
# HELP
# ============================================================

show_help() {
    cat <<EOF
Usage:
    $0 <command>

Commands:

    genkey
        Generate the Secure Boot signing key and request
        MOK enrollment.

    needs-rebuild
        Check whether v4l2loopback.ko exists for the newest
        installed kernel-devel.

        Exit status:
            0 = module missing, rebuild required
            1 = module exists, nothing required

        Intended primarily for systemd ExecCondition.

    rebuild
        Build, sign and install v4l2loopback only when the
        module does not already exist for the newest
        installed kernel-devel.

    reinstall
        Uninstall, restore source/configuration and rebuild.

    uninstall
        Remove installed v4l2loopback modules and
        configuration.

        Optionally:
            - stage MOK deletion
            - remove source repository
            - remove signing keys

    enable-systemd
        Install and enable:

            $SYSTEMD_SERVICE

        At boot systemd checks whether the module exists.

        Missing:
            rebuild is executed

        Exists:
            nothing is executed

    disable-systemd
        Disable and remove the systemd service.

    help
        Show this help.

Module:
    $MODULE_NAME

Module options:
    ${MODULE_OPTS[*]}

Source:
    $REPO_DIR

Installed command:
    $PROGRAM_PATH

Systemd service:
    $SYSTEMD_SERVICE

EOF
}

# ============================================================
# MAIN
# ============================================================

cmd="${1:-help}"

case "$cmd" in
    genkey)
        gen_signing_key
        ;;

    needs-rebuild)
        needs_rebuild
        ;;

    rebuild)
        rebuild_module
        ;;

    reinstall)
        reinstall_module
        ;;

    uninstall)
        uninstall_module
        ;;

    enable-systemd)
        enable_systemd
        ;;

    disable-systemd)
        disable_systemd
        ;;

    help | --help | -h)
        show_help
        ;;

    *)
        echo "❌ Unknown command: $cmd"
        echo
        show_help
        exit 1
        ;;
esac