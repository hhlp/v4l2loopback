# 🎥 v4l2loopback – Secure Boot Management for Fedora

Secure Boot compatible management script for building, signing, installing, rebuilding, reinstalling, and removing the [`v4l2loopback`](https://github.com/v4l2loopback/v4l2loopback) kernel module on Fedora.

This version is intentionally simple:

* No DNF hook.
* Optional automatic check at boot using systemd.
* Works only with the **newest installed `kernel-devel`**.
* Before compiling, it checks whether the module already exists for that kernel.
* If the `.ko` file already exists, it reports it and does nothing.
* If the `.ko` file does not exist, it compiles, signs, installs, and runs `depmod`.
* Secure Boot signing is supported with MOK.
* systemd integration uses `ExecCondition=` so `rebuild` is executed only when the module is missing.
* `enable-systemd` is idempotent: it creates the unit only if it does not already exist, enables it only if needed, and then runs the check immediately.
* `disable-systemd` is state-aware: it disables and removes only what is present, reloads systemd only when changes were made, and clears a failed state only when applicable.
* `genkey`, `needs-rebuild`, `rebuild`, `reinstall`, `uninstall`, `enable-systemd`, `disable-systemd`, and `help` are available.

---

# 1. Requirements

Install the required packages:

```bash
sudo dnf install -y \
    git \
    gcc \
    make \
    kernel-devel \
    openssl \
    mokutil \
    dracut
```

Optional but recommended for checking the virtual camera:

```bash
sudo dnf install -y v4l-utils
```

Check the running kernel:

```bash
uname -r
```

List installed `kernel-devel` packages:

```bash
rpm -q kernel-devel
```

---

# 2. Installation

For RPM/COPR testing, the package is:

```text
v4l2loopback-manager
```

and the installed management command is:

```text
/usr/sbin/v4l2loopback
```

Install from COPR with:

```bash
sudo dnf copr enable hhlp/v4l2loopback
sudo dnf install v4l2loopback-manager
```

Verify the RPM installation:

```bash
rpm -q v4l2loopback-manager
rpm -qf /usr/sbin/v4l2loopback
command -v v4l2loopback
v4l2loopback help
```

For testing directly from the source tree instead of the RPM:

```bash
sudo install -m 755 \
    v4l2loopback.sh \
    /usr/sbin/v4l2loopback
```

The source file is named `v4l2loopback.sh`, while the installed command
intentionally has no `.sh` suffix.

---

# 3. Available commands

The script supports:

```text
genkey
needs-rebuild
rebuild
reinstall
uninstall
enable-systemd
disable-systemd
help
```

General syntax:

```bash
sudo v4l2loopback <command>
```

Examples:

```bash
sudo v4l2loopback genkey
sudo v4l2loopback needs-rebuild
sudo v4l2loopback rebuild
sudo v4l2loopback reinstall
sudo v4l2loopback uninstall
sudo v4l2loopback enable-systemd
sudo v4l2loopback disable-systemd
sudo v4l2loopback help
```

---

# 4. Configuration

The source repository is:

```bash
REPO_URL="https://github.com/v4l2loopback/v4l2loopback.git"
REPO_DIR="/usr/src/v4l2loopback"
```

The module configuration is:

```bash
MODULE_NAME="v4l2loopback"
MODULE_SUBDIR="updates"
```

The default module options are:

```bash
MODULE_OPTS=(
    "devices=1"
    "video_nr=10"
    "card_label=VirtualCam"
    "exclusive_caps=1"
)
```

With this configuration the expected virtual video device is normally:

```text
/dev/video10
```

with the label:

```text
VirtualCam
```

---

# 5. Module options

## `devices=1`

Creates one virtual video device:

```text
devices=1
```

For example, to request two devices:

```text
devices=2
```

When configuring multiple devices, the other module parameters may also need multiple values.

---

## `video_nr=10`

Requests video device number 10:

```text
video_nr=10
```

Normally this creates:

```text
/dev/video10
```

Check available devices:

```bash
ls -l /dev/video*
```

---

## `card_label=VirtualCam`

Sets the user-visible name of the virtual camera:

```text
card_label=VirtualCam
```

Check it with:

```bash
v4l2-ctl --list-devices
```

---

## `exclusive_caps=1`

Enables exclusive capability behavior:

```text
exclusive_caps=1
```

This option is commonly useful for browsers and video-conferencing applications.

---

# 6. Persistent configuration

The script creates:

```text
/etc/modprobe.d/v4l2loopback.conf
```

with a line equivalent to:

```text
options v4l2loopback devices=1 video_nr=10 card_label=VirtualCam exclusive_caps=1
```

It also creates:

```text
/etc/modules-load.d/v4l2loopback.conf
```

containing:

```text
v4l2loopback
```

This allows the module to be loaded automatically when the relevant kernel is running.

---

# 7. Secure Boot

Check Secure Boot:

```bash
mokutil --sb-state
```

A Secure Boot enabled system normally reports:

```text
SecureBoot enabled
```

Third-party kernel modules generally need to be signed with a trusted key when Secure Boot is enabled.

The script therefore supports generating a dedicated MOK signing key.

---

# 8. Generate the signing key

Run:

```bash
sudo v4l2loopback genkey
```

The script creates:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

The private key is:

```text
/var/lib/shim-signed/mok/v4l.key
```

The certificate is:

```text
/var/lib/shim-signed/mok/v4l.der
```

The certificate subject is:

```text
CN=V4L2Loopback Module Signing
```

The private key is protected with mode:

```text
0600
```

---

# 9. MOK enrollment

During `genkey`, the script runs:

```bash
mokutil --import /var/lib/shim-signed/mok/v4l.der
```

You will be asked to create a temporary password.

Check pending enrollment with:

```bash
mokutil --list-new
```

Then reboot:

```bash
sudo reboot
```

During startup, the blue MOK Manager screen should appear.

Choose:

```text
Enroll MOK
```

and complete the enrollment using the temporary password.

After Fedora starts again, verify:

```bash
mokutil --list-enrolled
```

Look for:

```text
V4L2Loopback Module Signing
```

---

# 10. Clone the source repository

The script expects the source repository at:

```text
/usr/src/v4l2loopback
```

Clone it with:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

Check it:

```bash
ls -la /usr/src/v4l2loopback
```

---

# 11. How the newest kernel is selected

The script does **not** build for every installed kernel.

It determines the newest installed `kernel-devel` package with logic equivalent to:

```bash
rpm -q kernel-devel \
    --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
    sort -V |
    tail -n 1
```

For example, if these packages are installed:

```text
6.17.3-300.fc43.x86_64
6.17.4-300.fc43.x86_64
6.17.5-300.fc43.x86_64
```

the selected kernel is:

```text
6.17.5-300.fc43.x86_64
```

Only that kernel is considered by `rebuild`.

---

# 12. Important: newest installed kernel vs running kernel

The newest installed kernel may not be the currently running kernel.

For example:

```bash
uname -r
```

could show:

```text
6.17.4-300.fc43.x86_64
```

while the newest installed `kernel-devel` is:

```text
6.17.5-300.fc43.x86_64
```

This normally means that Fedora has installed a newer kernel but the system has not yet rebooted into it.

The script will build for:

```text
6.17.5-300.fc43.x86_64
```

not for the currently running:

```text
6.17.4-300.fc43.x86_64
```

After the build, reboot to use the new kernel:

```bash
sudo reboot
```

---

# 13. `rebuild` behavior

Run:

```bash
sudo v4l2loopback rebuild
```

The script determines the newest installed kernel and constructs this path:

```text
/lib/modules/<latest-kernel>/updates/v4l2loopback.ko
```

For example:

```text
/lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko
```

It then checks whether this file already exists.

---

# 14. If the `.ko` already exists

If:

```text
/lib/modules/<latest-kernel>/updates/v4l2loopback.ko
```

already exists, the script reports it and exits successfully.

Example:

```text
🔎 Checking existing module:
   /lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko

✅ Module already exists for kernel:
   6.17.5-300.fc43.x86_64

📦 Existing module:
   /lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko

ℹ️ Nothing to do.
```

In this case the script does **not** execute:

```text
make clean
make
sign-file
install
depmod
modprobe
```

The existing module is left untouched.

---

# 15. If the `.ko` does not exist

If the module does not exist for the newest kernel, the script performs:

```text
newest kernel-devel
        │
        ▼
check .ko
        │
        ▼
module missing
        │
        ▼
check source repository
        │
        ▼
check signing keys
        │
        ▼
check kernel headers
        │
        ▼
make clean
        │
        ▼
make KERNELRELEASE=<kernel>
        │
        ▼
v4l2loopback.ko
        │
        ▼
sign-file
        │
        ▼
install
        │
        ▼
depmod
```

---

# 16. Compilation

The build uses the selected kernel version:

```bash
make KERNELRELEASE="$kver"
```

The corresponding kernel development directory is:

```text
/usr/src/kernels/<kernel-version>
```

For example:

```text
/usr/src/kernels/6.17.5-300.fc43.x86_64
```

The expected build result is:

```text
/usr/src/v4l2loopback/v4l2loopback.ko
```

---

# 17. Module signing

The module is signed with:

```text
SHA-256
```

using:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

The signing utility comes from:

```text
/usr/src/kernels/<kernel>/scripts/sign-file
```

The equivalent operation is:

```bash
/usr/src/kernels/<kernel>/scripts/sign-file \
    sha256 \
    /var/lib/shim-signed/mok/v4l.key \
    /var/lib/shim-signed/mok/v4l.der \
    v4l2loopback.ko
```

---

# 18. Module installation

The signed module is installed as:

```text
/lib/modules/<kernel>/updates/v4l2loopback.ko
```

For example:

```text
/lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko
```

After installation the script runs:

```bash
depmod -a <kernel-version>
```

---

# 19. Loading the module

The script only reloads `v4l2loopback` if the selected newest kernel is also the currently running kernel.

That means:

```text
latest kernel-devel == uname -r
```

If they match, the script executes logic equivalent to:

```bash
sudo modprobe -r v4l2loopback

sudo modprobe \
    v4l2loopback \
    devices=1 \
    video_nr=10 \
    card_label=VirtualCam \
    exclusive_caps=1
```

Internally the options are stored as a Bash array:

```bash
MODULE_OPTS=(
    "devices=1"
    "video_nr=10"
    "card_label=VirtualCam"
    "exclusive_caps=1"
)
```

and passed safely as:

```bash
sudo modprobe \
    "$MODULE_NAME" \
    "${MODULE_OPTS[@]}"
```

---

# 20. If the newest kernel is not running

If the module has been built for a newer kernel than the currently running one, the script does not attempt to load it.

It reports something similar to:

```text
ℹ️ The module was built for a newer kernel than the
currently running kernel.

Running kernel:
   6.17.4-300.fc43.x86_64

Newest kernel:
   6.17.5-300.fc43.x86_64

Reboot to use the new kernel:

   sudo reboot
```

This is expected behavior.

---

# 21. Verify the installed module

For the currently running kernel:

```bash
modinfo v4l2loopback
```

Useful fields:

```bash
modinfo v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

The signer should normally contain:

```text
V4L2Loopback Module Signing
```

---

# 22. Verify a module for a specific kernel

You can inspect the module for a kernel that is not currently running with:

```bash
modinfo -k <kernel-version> v4l2loopback
```

For example:

```bash
modinfo -k \
    6.17.5-300.fc43.x86_64 \
    v4l2loopback
```

Filter the signing information:

```bash
modinfo -k \
    6.17.5-300.fc43.x86_64 \
    v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

---

# 23. Verify the virtual camera

Check whether the module is loaded:

```bash
lsmod | grep v4l2loopback
```

Check video devices:

```bash
ls -l /dev/video*
```

With the default configuration you should normally see:

```text
/dev/video10
```

Check devices with `v4l2-ctl`:

```bash
v4l2-ctl --list-devices
```

Inspect `/dev/video10`:

```bash
v4l2-ctl \
    --device=/dev/video10 \
    --all
```

---

# 24. `reinstall`

Run:

```bash
sudo v4l2loopback reinstall
```

The reinstall process performs:

```text
reinstall
    │
    ▼
uninstall
    │
    ├── unload module
    ├── optionally stage MOK deletion
    ├── remove installed v4l2loopback modules
    ├── remove configuration
    ├── optionally remove repository
    └── optionally remove keys
    │
    ▼
prepare repository
    │
    ▼
write configuration
    │
    ▼
dracut -f
    │
    ▼
rebuild
```

The final `rebuild` still follows the normal rule:

> Only build for the newest installed `kernel-devel`.

---

# 25. Important consideration when using `reinstall`

During uninstall you may be asked:

```text
Remove source repository at /usr/src/v4l2loopback? [y/N]
```

and:

```text
Remove local signing key files in /var/lib/shim-signed/mok? [y/N]
```

If you remove the local signing keys, the rebuild cannot sign a new module until you generate another key.

Therefore, for a normal reinstall, it is usually preferable to preserve:

```text
v4l.key
v4l.der
```

unless you deliberately want to create and enroll a new signing key.

---

# 26. `uninstall`

Run:

```bash
sudo v4l2loopback uninstall
```

The script:

1. Unloads `v4l2loopback` if it is loaded.
2. Looks for the signing certificate.
3. Optionally stages MOK certificate deletion.
4. Removes installed `v4l2loopback.ko` files.
5. Runs `depmod` for affected kernels.
6. Removes persistent configuration.
7. Optionally removes the source repository.
8. Optionally removes local signing keys.

---

# 27. MOK deletion

If the local certificate exists:

```text
/var/lib/shim-signed/mok/v4l.der
```

the script can use it directly.

Otherwise, the script attempts to export enrolled certificates and searches their subject for:

```text
CN=V4L2Loopback Module Signing
```

If found, you are asked:

```text
Stage MOK certificate deletion? [y/N]
```

If you answer:

```text
y
```

the script invokes:

```bash
mokutil --delete <certificate.der>
```

Check pending deletion with:

```bash
mokutil --list-delete
```

Then reboot and complete the deletion through MOK Manager.

---

# 28. Removing installed modules

The uninstall operation searches under:

```text
/lib/modules/*
```

for:

```text
updates/v4l2loopback.ko
```

For example:

```text
/lib/modules/6.17.4-300.fc43.x86_64/updates/v4l2loopback.ko
/lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko
```

Matching files are removed.

The script then executes:

```bash
depmod -a <kernel>
```

for each affected kernel.

---

# 29. No DNF hook

This version intentionally does **not** install a DNF post-transaction hook.

There is no:

```text
enable-hook
```

command.

There is also no:

```text
/etc/dnf/plugins/post-transaction-actions.d/v4l2loopback-rebuild.sh
```

created by the script.

Instead, the script can optionally install a **systemd oneshot service** that performs the check at boot.

The service is:

```text
/etc/systemd/system/v4l2loopback-rebuild.service
```

This unit is generated dynamically by `v4l2loopback enable-systemd`.
It is not a static RPM-owned systemd unit.

It does not rebuild unconditionally. It first runs:

```text
/usr/sbin/v4l2loopback needs-rebuild
```

If the module already exists, systemd skips the rebuild.

If the module is missing, systemd runs:

```bash
sudo v4l2loopback rebuild
```

The script always selects the newest installed `kernel-devel`.

---

# 30. `needs-rebuild`

Run:

```bash
sudo v4l2loopback needs-rebuild
```

This command determines the newest installed `kernel-devel` and checks:

```text
/lib/modules/<latest-kernel>/updates/v4l2loopback.ko
```

Its exit status is intentionally designed for systemd `ExecCondition=`:

```text
0 = module is missing -> rebuild required
1 = module exists     -> nothing required
```

The check is intentionally based only on whether the expected `.ko` file exists. It does **not** verify the module signature on every boot.

This is consistent with the script workflow: when the module is missing, `rebuild` compiles it, signs it, installs the signed `.ko`, and runs `depmod`. Therefore, a module successfully created by this script is signed before it is installed.

In other words:

```text
.ko missing
    │
    ▼
needs-rebuild -> exit 0
    │
    ▼
rebuild
    │
    ├── compile
    ├── sign
    ├── install signed .ko
    └── depmod
```

An existing `.ko` is trusted as already prepared by this workflow and is left untouched.

Example:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

If the result is:

```text
0
```

the module is missing.

If the result is:

```text
1
```

the module already exists and no build is needed.

When this command is used by systemd through `ExecCondition=`, exit status `1` is expected and means the condition evaluated to false. systemd therefore skips `ExecStart=`.

You may see output similar to:

```text
ExecCondition=/usr/sbin/v4l2loopback needs-rebuild
(code=exited, status=1/FAILURE)

v4l2loopback-rebuild.service: Skipped due to 'exec-condition'.
Condition check resulted in v4l2loopback-rebuild.service being skipped.
```

In this context, `status=1/FAILURE` does **not** mean that the service itself failed. It means:

```text
.ko exists
    │
    ▼
needs-rebuild returns 1
    │
    ▼
ExecCondition is false
    │
    ▼
ExecStart is skipped
    │
    ▼
nothing to rebuild
```

It also does not independently prove that an arbitrary existing `.ko` is signed; it only proves that the file exists. The signing guarantee comes from the script's own successful `rebuild` workflow.

---

# 31. Installation and systemd integration

With the RPM installed, verify that the management command belongs to the
package:

```bash
rpm -q v4l2loopback-manager
rpm -qf /usr/sbin/v4l2loopback
```

For source-tree testing only, it can be installed manually with:

```bash
sudo install -m 755 \
    v4l2loopback.sh \
    /usr/sbin/v4l2loopback
```

Enable the automatic systemd check at boot:

```bash
sudo v4l2loopback enable-systemd
```

This manages the following oneshot unit:

```text
v4l2loopback-rebuild.service
```

The service checks whether the expected module exists for the newest installed `kernel-devel`:

```text
/lib/modules/<latest-kernel>/updates/v4l2loopback.ko
```

If the `.ko` already exists, the rebuild is skipped. If it is missing, systemd runs the script's `rebuild` command, which compiles, signs, installs the module, and runs `depmod`.

The `enable-systemd` command is idempotent:

```text
unit missing
    -> create unit
    -> daemon-reload
    -> enable service

unit exists but disabled
    -> keep existing unit
    -> enable service

unit exists and enabled
    -> keep existing unit
    -> report that it is already enabled
```

After enabling the unit, the script also starts it once immediately so the same check can be tested without rebooting.

The generated service is conceptually equivalent to:

```ini
[Unit]
Description=Ensure v4l2loopback exists for newest installed kernel
After=local-fs.target
ConditionPathExists=/usr/sbin/v4l2loopback

[Service]
Type=oneshot
ExecCondition=/usr/sbin/v4l2loopback needs-rebuild
ExecStart=/usr/sbin/v4l2loopback rebuild

[Install]
WantedBy=multi-user.target
```

The key lines are:

```ini
ExecCondition=/usr/sbin/v4l2loopback needs-rebuild
ExecStart=/usr/sbin/v4l2loopback rebuild
```

`ExecCondition=` is evaluated first:

```text
needs-rebuild returns 1
    -> .ko exists
    -> condition is false
    -> ExecStart is skipped

needs-rebuild returns 0
    -> .ko is missing
    -> condition is true
    -> ExecStart runs rebuild
```

The complete boot-time flow is:

```text
                    SYSTEM BOOT
                         │
                         ▼
           v4l2loopback-rebuild.service
                         │
                         ▼
                   ExecCondition
                         │
                         ▼
                    needs-rebuild
                         │
               ┌─────────┴─────────┐
               │                   │
         .ko EXISTS          .ko IS MISSING
               │                   │
               ▼                   ▼
            exit 1              exit 0
               │                   │
               ▼                   ▼
        skip ExecStart          ExecStart
                                   │
                                   ▼
                    v4l2loopback rebuild
                                   │
                         ┌─────────┼─────────┐
                         ▼         ▼         ▼
                      compile     sign     install
                                             │
                                             ▼
                                           depmod
```

This avoids unnecessary compilation at every boot. The module is rebuilt only when `v4l2loopback.ko` is missing for the newest installed kernel.

---

# 32. Check and test the systemd service

Verify the service status:

```bash
systemctl status v4l2loopback-rebuild.service
```

Check whether it is enabled at boot:

```bash
systemctl is-enabled v4l2loopback-rebuild.service
```

You can manually run the same condition used by systemd:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

The exit status means:

```text
0  -> v4l2loopback.ko is missing
     -> rebuild is required

1  -> v4l2loopback.ko already exists
     -> no rebuild is required
```

This behavior is intentional because `needs-rebuild` is used as a systemd `ExecCondition=`.

Conceptually:

```text
needs-rebuild
      │
      ▼
Does v4l2loopback.ko exist?
      │
  ┌───┴───┐
  │       │
 YES      NO
  │       │
exit 1   exit 0
  │       │
  ▼       ▼
 skip    rebuild
```

You can simulate the boot-time check without rebooting:

```bash
sudo systemctl start v4l2loopback-rebuild.service
```

Then inspect the result:

```bash
systemctl status v4l2loopback-rebuild.service
```

If the module already exists, systemd may show output similar to:

```text
ExecCondition=/usr/sbin/v4l2loopback needs-rebuild
(code=exited, status=1/FAILURE)

v4l2loopback-rebuild.service: Skipped due to 'exec-condition'.
Condition check resulted in v4l2loopback-rebuild.service being skipped.
```

This is **expected**. In this context, `status=1/FAILURE` refers to the condition command returning `1`; it does not mean that the rebuild service itself failed. It means the `.ko` already exists, so `ExecStart=` was intentionally skipped.

View all service logs:

```bash
journalctl -u v4l2loopback-rebuild.service
```

View only logs from the current boot:

```bash
journalctl -b -u v4l2loopback-rebuild.service
```

---

# 33. Disable systemd integration

Disable the automatic boot-time check and remove the unit:

```bash
sudo v4l2loopback disable-systemd
```

The operation is state-aware and idempotent:

```text
enabled + unit exists
    -> disable service
    -> remove unit
    -> daemon-reload

disabled + unit exists
    -> nothing to disable
    -> remove unit
    -> daemon-reload

enabled + unit missing
    -> disable service
    -> nothing to remove
    -> daemon-reload

disabled + unit missing
    -> nothing to disable
    -> nothing to remove
    -> no daemon-reload required
```

More specifically, `disable-systemd`:

1. Checks whether `v4l2loopback-rebuild.service` is enabled.
2. Disables it only if it is currently enabled.
3. Checks whether `/etc/systemd/system/v4l2loopback-rebuild.service` exists.
4. Removes the unit file only if it exists.
5. Runs `systemctl daemon-reload` only when something actually changed.
6. Clears the failed state only if the service is currently marked as failed.

After disabling systemd integration, the module can still be checked or rebuilt manually:

```bash
sudo v4l2loopback needs-rebuild
sudo v4l2loopback rebuild
```

---

# 34. Typical first installation

Install the requirements:

```bash
sudo dnf install -y \
    git \
    gcc \
    make \
    kernel-devel \
    openssl \
    mokutil \
    dracut \
    v4l-utils
```

Install the manager package:

```bash
sudo dnf copr enable hhlp/v4l2loopback
sudo dnf install v4l2loopback-manager
```

Verify the installed command:

```bash
rpm -qf /usr/sbin/v4l2loopback
v4l2loopback help
```

Clone the source:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

Generate and request enrollment of the signing key:

```bash
sudo v4l2loopback genkey
```

Reboot:

```bash
sudo reboot
```

Complete MOK enrollment.

After returning to Fedora:

```bash
sudo v4l2loopback rebuild
```

Optionally enable the automatic boot-time check:

```bash
sudo v4l2loopback enable-systemd
```

Then verify:

```bash
modinfo v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

Check the virtual camera:

```bash
v4l2-ctl --list-devices
```

---

# 35. Typical workflow after a kernel update

Assume Fedora installs a new kernel.

If systemd integration is enabled, the normal workflow is simply:

```text
kernel update
    │
    ▼
reboot
    │
    ▼
systemd runs needs-rebuild
    │
    ├── .ko exists -> nothing to do
    │
    └── .ko missing -> rebuild
```

When `.ko` is missing, the rebuild path is:

```text
compile
   │
   ▼
sign
   │
   ▼
install signed .ko
   │
   ▼
depmod
```

When `.ko` already exists, the systemd condition returns `1` and the service is skipped without rebuilding.

You can still check manually:

```bash
rpm -q kernel-devel
```

and run:

```bash
sudo v4l2loopback rebuild
```

Two cases are possible.

## Case 1: the module already exists

The script reports:

```text
✅ Module already exists
ℹ️ Nothing to do.
```

No build occurs.

## Case 2: the module does not exist

The script:

```text
compile
   │
   ▼
sign
   │
   ▼
install
   │
   ▼
depmod
```

If the new kernel is not yet running, reboot:

```bash
sudo reboot
```

---

# 36. Check whether a build is needed manually

The easiest method is:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

You can also check the path manually.

Determine the newest kernel-devel:

```bash
LATEST_KERNEL="$(
    rpm -q kernel-devel \
        --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
        sort -V |
        tail -n 1
)"
```

Print it:

```bash
echo "$LATEST_KERNEL"
```

Check the expected module:

```bash
ls -l \
    "/lib/modules/$LATEST_KERNEL/updates/v4l2loopback.ko"
```

If the file exists, `rebuild` will do nothing.

If it does not exist, `rebuild` will create it.

---

# 37. Rebuild decision tree

```text
                rebuild
                   │
                   ▼
      newest installed kernel-devel
                   │
                   ▼
 /lib/modules/<kernel>/updates/v4l2loopback.ko
                   │
            ┌──────┴──────┐
            │             │
         EXISTS        MISSING
            │             │
            ▼             ▼
        report it       check repo
            │             │
            ▼             ▼
      nothing to do     check keys
                          │
                          ▼
                     check headers
                          │
                          ▼
                      compile
                          │
                          ▼
                        sign
                          │
                          ▼
                       install
                          │
                          ▼
                        depmod
                          │
                          ▼
              running kernel == latest?
                     ┌────┴────┐
                     │         │
                    yes        no
                     │         │
                     ▼         ▼
                 modprobe    tell user
                            to reboot
```

---

# 38. systemd decision tree

```text
                 boot
                   │
                   ▼
 v4l2loopback-rebuild.service
                   │
                   ▼
             ExecCondition
                   │
                   ▼
          needs-rebuild
                   │
            ┌──────┴──────┐
            │             │
         EXISTS        MISSING
            │             │
         exit 1         exit 0
            │             │
            ▼             ▼
      skip ExecStart   ExecStart
                          │
                          ▼
                       rebuild
                          │
                 ┌────────┼────────┐
                 ▼        ▼        ▼
              compile    sign    install
                                   │
                                   ▼
                                 depmod
```

This means the service can safely be enabled permanently without rebuilding the module at every boot.

The `exit 1` branch is a normal false `ExecCondition=` result. Although systemd may display `status=1/FAILURE` for the condition command, the intended outcome is to skip `ExecStart=` because there is nothing to rebuild.

---

# 39. ShellCheck

Install ShellCheck:

```bash
sudo dnf install -y ShellCheck
```

Run:

```bash
shellcheck v4l2loopback.sh
```

Module options are stored as:

```bash
MODULE_OPTS=(
    "devices=1"
    "video_nr=10"
    "card_label=VirtualCam"
    "exclusive_caps=1"
)
```

For `modprobe`, use:

```bash
"${MODULE_OPTS[@]}"
```

because every option must be passed as a separate argument.

Conceptually:

```text
"${MODULE_OPTS[@]}"

        │
        ├── devices=1
        ├── video_nr=10
        ├── card_label=VirtualCam
        └── exclusive_caps=1
```

For generating `/etc/modprobe.d/v4l2loopback.conf`, the script uses:

```bash
"${MODULE_OPTS[*]}"
```

because the configuration requires a single textual line.

---

# 40. Troubleshooting

## systemd service does not run `rebuild`

Check the condition manually:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

If it returns `1`, the module already exists, so systemd correctly skips `ExecStart=`. Seeing `status=1/FAILURE` for `ExecCondition=` is expected in this case and does not mean the service rebuild failed.

Check the expected file:

```bash
LATEST_KERNEL="$(
    rpm -q kernel-devel \
        --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
        sort -V |
        tail -n 1
)"

ls -l "/lib/modules/$LATEST_KERNEL/updates/v4l2loopback.ko"
```

Check service status:

```bash
systemctl status v4l2loopback-rebuild.service
```

Check logs:

```bash
journalctl -b -u v4l2loopback-rebuild.service
```

## systemd service is not enabled

Check:

```bash
systemctl is-enabled v4l2loopback-rebuild.service
```

Enable it again with:

```bash
sudo v4l2loopback enable-systemd
```

## No `kernel-devel` installed

If the script reports:

```text
No kernel-devel packages found
```

install it:

```bash
sudo dnf install -y kernel-devel
```

Check:

```bash
rpm -q kernel-devel
```

Then:

```bash
sudo v4l2loopback rebuild
```

---

## Source repository is missing

If the script reports:

```text
Source repository not found
```

clone it:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

Then:

```bash
sudo v4l2loopback rebuild
```

---

## Signing keys are missing

Check:

```bash
sudo ls -l /var/lib/shim-signed/mok/
```

Expected:

```text
v4l.key
v4l.der
```

If they are missing:

```bash
sudo v4l2loopback genkey
```

Complete MOK enrollment after reboot before relying on the signed module under Secure Boot.

---

## Module rejected by Secure Boot

If `modprobe` reports something similar to:

```text
Key was rejected by service
```

check:

```bash
mokutil --sb-state
```

Then:

```bash
mokutil --list-enrolled
```

Look for:

```text
V4L2Loopback Module Signing
```

Check the signature:

```bash
modinfo v4l2loopback |
    grep -E '^(signer|sig_key|sig_hashalgo):'
```

---

## New module was built but not loaded

Compare:

```bash
uname -r
```

with:

```bash
rpm -q kernel-devel \
    --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
    sort -V |
    tail -n 1
```

If they are different, the module was built for a newer installed kernel.

Reboot:

```bash
sudo reboot
```

---

## `/dev/video10` does not exist

Check whether the module is loaded:

```bash
lsmod | grep v4l2loopback
```

Check kernel messages:

```bash
dmesg | grep -i v4l2loopback
```

Try loading manually:

```bash
sudo modprobe \
    v4l2loopback \
    devices=1 \
    video_nr=10 \
    card_label=VirtualCam \
    exclusive_caps=1
```

Check again:

```bash
ls -l /dev/video*
```

---

## Module is busy

If:

```bash
sudo modprobe -r v4l2loopback
```

cannot unload the module, check which program is using the virtual camera:

```bash
sudo fuser -v /dev/video10
```

Close that application and try again.

---

# 41. Useful diagnostic commands

Running kernel:

```bash
uname -r
```

Installed kernels:

```bash
rpm -q kernel
```

Installed kernel development packages:

```bash
rpm -q kernel-devel
```

Newest installed `kernel-devel`:

```bash
rpm -q kernel-devel \
    --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
    sort -V |
    tail -n 1
```

Secure Boot state:

```bash
mokutil --sb-state
```

Pending MOK enrollment:

```bash
mokutil --list-new
```

Pending MOK deletion:

```bash
mokutil --list-delete
```

Enrolled MOK certificates:

```bash
mokutil --list-enrolled
```

Loaded module:

```bash
lsmod | grep v4l2loopback
```

Module information:

```bash
modinfo v4l2loopback
```

Virtual video devices:

```bash
v4l2-ctl --list-devices
```

Kernel messages:

```bash
dmesg | grep -i v4l2loopback
```

Check whether a rebuild is required:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

systemd service status:

```bash
systemctl status v4l2loopback-rebuild.service
```

systemd service enabled state:

```bash
systemctl is-enabled v4l2loopback-rebuild.service
```

systemd logs:

```bash
journalctl -b -u v4l2loopback-rebuild.service
```

---

# 42. Directory layout

A typical installation looks like:

```text
/
├── usr/
│   ├── sbin/
│   │   └── v4l2loopback
│   │
│   └── src/
│       ├── kernels/
│       │   └── <kernel-version>/
│       │
│       └── v4l2loopback/
│
├── var/
│   └── lib/
│       └── shim-signed/
│           └── mok/
│               ├── v4l.key
│               └── v4l.der
│
├── etc/
│   ├── systemd/
│   │   └── system/
│   │       └── v4l2loopback-rebuild.service
│   │
│   ├── modprobe.d/
│   │   └── v4l2loopback.conf
│   │
│   └── modules-load.d/
│       └── v4l2loopback.conf
│
└── lib/
    └── modules/
        └── <kernel-version>/
            └── updates/
                └── v4l2loopback.ko
```

There is deliberately no DNF hook directory or hook script managed by this project.

The systemd service exists only when `enable-systemd` has been executed.

---

# 43. Security notes

Protect the private signing key:

```text
/var/lib/shim-signed/mok/v4l.key
```

The script sets:

```text
0600
```

permissions.

Do not commit the private key to Git.

A useful `.gitignore` may contain:

```gitignore
*.key
*.pem
*.der
*.crt
*.cer
```

The DER certificate itself is public material, but keeping locally generated signing material outside the repository helps avoid accidental machine-specific files being committed.

---

# 44. Command summary

| Command           | Purpose                                                                              |
| ----------------- | ------------------------------------------------------------------------------------ |
| `genkey`          | Generate signing key and request MOK enrollment                                      |
| `needs-rebuild`   | Return whether the newest kernel is missing `v4l2loopback.ko`                        |
| `rebuild`         | Check/build only for the newest installed `kernel-devel`                             |
| `reinstall`       | Uninstall, restore configuration/source and rebuild                                  |
| `uninstall`       | Remove modules/config and optionally MOK/source/keys                                 |
| `enable-systemd`  | Create if missing, enable if needed, and run the boot-time systemd check immediately |
| `disable-systemd` | Disable/remove only when present and clean systemd state as needed                   |
| `help`            | Display command help                                                                 |

There is intentionally no:

```text
enable-hook
```

command.

---

# 45. Main design principle

The central behavior of this version is:

```text
boot or manual check
        │
        ▼
newest installed kernel-devel
        │
        ▼
does v4l2loopback.ko exist?
        │
   ┌────┴────┐
   │         │
  yes        no
   │         │
   ▼         ▼
nothing    rebuild
to do        │
             ├── compile
             ├── sign
             ├── install
             └── depmod
```

This prevents unnecessary rebuilding or overwriting of a module that has already been prepared for the newest installed kernel.

With systemd enabled, the same logic is evaluated automatically at boot using `ExecCondition=`.

The existence test is deliberately simple: the service checks whether the expected `.ko` exists. If it is missing, the script rebuilds it and signs it before installation. If it already exists, the file is preserved and no signature re-check is performed during the boot-time condition.

---

# 46. RPM removal test

Before removing the RPM, test the cleanup commands while the management
command still exists:

```bash
sudo v4l2loopback uninstall
sudo v4l2loopback disable-systemd
```

Then remove the package:

```bash
sudo dnf remove v4l2loopback-manager
```

Verify that the RPM-owned command was removed:

```bash
rpm -q v4l2loopback-manager
test ! -e /usr/sbin/v4l2loopback
```

The RPM removal itself should not silently delete machine-local state such as
locally built kernel modules, MOK enrollment, signing keys, the cloned source
repository, or the dynamically generated systemd unit. The `%preun` scriptlet
may print a reminder telling the administrator to run the cleanup commands
before final package removal.

---

# 47. Project

This script is a Fedora-oriented helper around the upstream:

[`v4l2loopback`](https://github.com/v4l2loopback/v4l2loopback)

The upstream project provides the kernel module itself.

This management script adds:

* Fedora-oriented source placement.
* Secure Boot signing.
* MOK management.
* Persistent module configuration.
* Selection of only the newest installed kernel.
* Detection of an already-installed `.ko`.
* Conditional build only when necessary.
* Optional boot-time systemd validation with `ExecCondition=`.
* Built-in commands to enable and disable the systemd service.
* Reinstallation and removal workflows.