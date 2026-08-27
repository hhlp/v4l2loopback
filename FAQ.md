# 🎥 v4l2loopback – Secure Boot Management for Fedora

Frequently Asked Questions about the Fedora `v4l2loopback` management script, Secure Boot signing, MOK enrollment, kernel updates, and systemd integration.

# v4l2loopback Manager for Fedora — FAQ

Frequently Asked Questions about the Fedora `v4l2loopback` management script, Secure Boot, MOK enrollment, kernel updates, module signing, BIOS/UEFI updates, and systemd integration.

---

## Table of Contents

* [1. General](#1-general)

  * [1.1 What does this script do?](#11-what-does-this-script-do)
  * [1.2 What commands are available?](#12-what-commands-are-available)
  * [1.3 Where should the script be installed?](#13-where-should-the-script-be-installed)
* [2. Kernel selection and rebuild](#2-kernel-selection-and-rebuild)

  * [2.1 Does the script build for every installed kernel?](#21-does-the-script-build-for-every-installed-kernel)
  * [2.2 Does the newest kernel have to be running?](#22-does-the-newest-kernel-have-to-be-running)
  * [2.3 Where is the module installed?](#23-where-is-the-module-installed)
  * [2.4 What does `needs-rebuild` do?](#24-what-does-needs-rebuild-do)
  * [2.5 What do exit codes 0 and 1 mean?](#25-what-do-exit-codes-0-and-1-mean)
  * [2.6 What happens when the `.ko` is missing?](#26-what-happens-when-the-ko-is-missing)
  * [2.7 What happens when the `.ko` already exists?](#27-what-happens-when-the-ko-already-exists)
  * [2.8 Why check again inside `rebuild`?](#28-why-check-again-inside-rebuild)
* [3. Secure Boot and module signing](#3-secure-boot-and-module-signing)

  * [3.1 Why does the module need to be signed?](#31-why-does-the-module-need-to-be-signed)
  * [3.2 When is the module signed?](#32-when-is-the-module-signed)
  * [3.3 Does `needs-rebuild` verify the signature?](#33-does-needs-rebuild-verify-the-signature)
  * [3.4 How can I verify the module signature?](#34-how-can-i-verify-the-module-signature)
  * [3.5 What signing algorithm is used?](#35-what-signing-algorithm-is-used)
  * [3.6 Where are the signing keys stored?](#36-where-are-the-signing-keys-stored)
* [4. MOK enrollment](#4-mok-enrollment)

  * [4.1 What is MOK?](#41-what-is-mok)
  * [4.2 How do I check Secure Boot?](#42-how-do-i-check-secure-boot)
  * [4.3 How do I generate and enroll the key?](#43-how-do-i-generate-and-enroll-the-key)
  * [4.4 How do I verify that the key is enrolled?](#44-how-do-i-verify-that-the-key-is-enrolled)
* [5. systemd integration](#5-systemd-integration)

  * [5.1 Why use systemd instead of a DNF hook?](#51-why-use-systemd-instead-of-a-dnf-hook)
  * [5.2 Is there a systemd timer?](#52-is-there-a-systemd-timer)
  * [5.3 How does the systemd service work?](#53-how-does-the-systemd-service-work)
  * [5.4 Why does systemd show `status=1/FAILURE`?](#54-why-does-systemd-show-status1failure)
  * [5.5 What does `Skipped due to exec-condition` mean?](#55-what-does-skipped-due-to-exec-condition-mean)
  * [5.6 How do I enable systemd integration?](#56-how-do-i-enable-systemd-integration)
  * [5.7 Does `enable-systemd` overwrite an existing service?](#57-does-enable-systemd-overwrite-an-existing-service)
  * [5.8 How do I test the service without rebooting?](#58-how-do-i-test-the-service-without-rebooting)
  * [5.9 How do I disable systemd integration?](#59-how-do-i-disable-systemd-integration)
* [6. Kernel updates](#6-kernel-updates)

  * [6.1 What happens after a Fedora kernel update?](#61-what-happens-after-a-fedora-kernel-update)
  * [6.2 What happens on the following reboot?](#62-what-happens-on-the-following-reboot)
* [7. BIOS and UEFI firmware updates](#7-bios-and-uefi-firmware-updates)

  * [7.1 Do I need to reinstall after a BIOS update?](#71-do-i-need-to-reinstall-after-a-bios-update)
  * [7.2 What if the MOK disappears?](#72-what-if-the-mok-disappears)
  * [7.3 When should I generate a new key?](#73-when-should-i-generate-a-new-key)
* [8. Reinstall and uninstall](#8-reinstall-and-uninstall)

  * [8.1 What does `reinstall` do?](#81-what-does-reinstall-do)
  * [8.2 Should I remove the signing keys during reinstall?](#82-should-i-remove-the-signing-keys-during-reinstall)
  * [8.3 What is the difference between `uninstall` and `disable-systemd`?](#83-what-is-the-difference-between-uninstall-and-disable-systemd)
* [9. Troubleshooting](#9-troubleshooting)

  * [9.1 What if the source repository is missing?](#91-what-if-the-source-repository-is-missing)
  * [9.2 What if `kernel-devel` is missing?](#92-what-if-kernel-devel-is-missing)
  * [9.3 What if the signing keys are missing?](#93-what-if-the-signing-keys-are-missing)
  * [9.4 Why do I get `Key was rejected by service`?](#94-why-do-i-get-key-was-rejected-by-service)
  * [9.5 Why does `/dev/video10` not exist?](#95-why-does-devvideo10-not-exist)
  * [9.6 Why can't I unload the module?](#96-why-cant-i-unload-the-module)
  * [9.7 How can I quickly diagnose the installation?](#97-how-can-i-quickly-diagnose-the-installation)
* [10. Design summary](#10-design-summary)

---

# 1. General

## 1.1 What does this script do?

The script manages `v4l2loopback` on Fedora with Secure Boot support.

It can:

* Generate a MOK signing key.
* Request MOK enrollment.
* Determine the newest installed `kernel-devel`.
* Check whether `v4l2loopback.ko` already exists.
* Compile the module only when necessary.
* Sign the module.
* Install it under `/lib/modules`.
* Run `depmod`.
* Load the module when appropriate.
* Configure an optional systemd boot-time check.
* Reinstall or uninstall the module.

---

## 1.2 What commands are available?

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

For example:

```bash
sudo /usr/local/bin/v4l2loopback.sh help
```

---

## 1.3 Where should the script be installed?

The current systemd-based configuration assumes:

```text
/usr/local/bin/v4l2loopback.sh
```

Install it with:

```bash
sudo install -m 755 \
    v4l2loopback.sh \
    /usr/local/bin/v4l2loopback.sh
```

Use this path consistently in:

* Documentation.
* Manual commands.
* `ConditionPathExists=`.
* `ExecCondition=`.
* `ExecStart=`.

---

# 2. Kernel selection and rebuild

## 2.1 Does the script build for every installed kernel?

No.

It intentionally selects only the newest installed `kernel-devel`.

The logic is equivalent to:

```bash
rpm -q kernel-devel \
    --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' |
    sort -V |
    tail -n 1
```

For example:

```text
6.17.3-300.fc43.x86_64
6.17.4-300.fc43.x86_64
6.17.5-300.fc43.x86_64
```

selects:

```text
6.17.5-300.fc43.x86_64
```

---

## 2.2 Does the newest kernel have to be running?

No.

For example:

```text
Running:
6.17.4-300.fc43.x86_64

Newest installed kernel-devel:
6.17.5-300.fc43.x86_64
```

The script builds for:

```text
6.17.5-300.fc43.x86_64
```

If that is not the running kernel, the script installs the module but does not attempt to load it into the older kernel.

Afterward:

```bash
sudo reboot
```

---

## 2.3 Where is the module installed?

The expected path is:

```text
/lib/modules/<kernel>/updates/v4l2loopback.ko
```

For example:

```text
/lib/modules/6.17.5-300.fc43.x86_64/updates/v4l2loopback.ko
```

---

## 2.4 What does `needs-rebuild` do?

Run:

```bash
sudo /usr/local/bin/v4l2loopback.sh needs-rebuild
```

It determines the newest installed `kernel-devel` and checks whether:

```text
/lib/modules/<latest-kernel>/updates/v4l2loopback.ko
```

exists.

The test is intentionally based on **file existence**.

---

## 2.5 What do exit codes 0 and 1 mean?

Check:

```bash
sudo /usr/local/bin/v4l2loopback.sh needs-rebuild
echo $?
```

The meanings are:

```text
0 → .ko is missing
    → rebuild required

1 → .ko exists
    → nothing needs to be rebuilt
```

This behavior is deliberately designed for systemd `ExecCondition=`.

```text
Does .ko exist?
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

---

## 2.6 What happens when the `.ko` is missing?

The rebuild sequence is:

```text
.ko missing
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

---

## 2.7 What happens when the `.ko` already exists?

Nothing is rebuilt.

The script does not perform:

```text
make clean
make
sign-file
install
depmod
```

The existing module is preserved.

---

## 2.8 Why check again inside `rebuild`?

There are two levels of protection:

```text
systemd
   │
   ▼
needs-rebuild
   │
   ▼
ExecStart
   │
   ▼
rebuild
   │
   ▼
check .ko again
```

`needs-rebuild` prevents systemd from invoking `rebuild` unnecessarily.

The second check prevents a manual invocation of `rebuild` from overwriting an already installed module.

---

# 3. Secure Boot and module signing

## 3.1 Why does the module need to be signed?

When Secure Boot is enabled, the kernel normally requires third-party kernel modules to have an acceptable signature.

Check Secure Boot with:

```bash
mokutil --sb-state
```

---

## 3.2 When is the module signed?

Before installation.

```text
make
 │
 ▼
v4l2loopback.ko
 │
 ▼
sign-file
 │
 ▼
signed v4l2loopback.ko
 │
 ▼
install
 │
 ▼
/lib/modules/<kernel>/updates/v4l2loopback.ko
```

Therefore a successful rebuild installs the signed module.

---

## 3.3 Does `needs-rebuild` verify the signature?

No.

It only checks:

```text
Does the expected .ko exist?
```

This is intentional.

The normal script-controlled creation path already performs:

```text
compile
→ sign
→ install
```

so an installed `.ko` produced by a successful `rebuild` has already been signed.

An arbitrary manually replaced `.ko` is not independently verified by `needs-rebuild`.

---

## 3.4 How can I verify the module signature?

For the running kernel:

```bash
modinfo v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

The signer should normally contain:

```text
V4L2Loopback Module Signing
```

For another installed kernel:

```bash
modinfo -k <kernel-version> v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

---

## 3.5 What signing algorithm is used?

The script uses:

```text
SHA-256
```

through:

```text
/usr/src/kernels/<kernel>/scripts/sign-file
```

Conceptually:

```bash
sign-file \
    sha256 \
    v4l.key \
    v4l.der \
    v4l2loopback.ko
```

---

## 3.6 Where are the signing keys stored?

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

Where:

```text
v4l.key → private signing key
v4l.der → public X.509 certificate
```

The private key should have:

```text
0600
```

permissions.

---

# 4. MOK enrollment

## 4.1 What is MOK?

MOK means **Machine Owner Key**.

It allows a user-controlled signing certificate to be enrolled so that modules signed with the associated private key can be trusted when Secure Boot is enabled.

The certificate generated by this project uses:

```text
CN=V4L2Loopback Module Signing
```

---

## 4.2 How do I check Secure Boot?

```bash
mokutil --sb-state
```

Typical result:

```text
SecureBoot enabled
```

---

## 4.3 How do I generate and enroll the key?

Run:

```bash
sudo /usr/local/bin/v4l2loopback.sh genkey
```

The script generates the key and certificate and requests MOK enrollment.

Check:

```bash
mokutil --list-new
```

Then reboot:

```bash
sudo reboot
```

Use MOK Manager to complete the enrollment.

---

## 4.4 How do I verify that the key is enrolled?

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

You should find:

```text
V4L2Loopback Module Signing
```

---

# 5. systemd integration

## 5.1 Why use systemd instead of a DNF hook?

The design deliberately separates kernel package installation from module compilation.

```text
kernel update
    │
    ▼
reboot
    │
    ▼
systemd
    │
    ▼
needs-rebuild
```

There is no DNF post-transaction hook.

---

## 5.2 Is there a systemd timer?

No.

The project uses a `Type=oneshot` service at boot.

There is no need to periodically rebuild or check the module while the machine is running.

---

## 5.3 How does the systemd service work?

Conceptually:

```ini
[Unit]
Description=Ensure v4l2loopback exists for newest installed kernel
After=local-fs.target
ConditionPathExists=/usr/local/bin/v4l2loopback.sh

[Service]
Type=oneshot
ExecCondition=/usr/local/bin/v4l2loopback.sh needs-rebuild
ExecStart=/usr/local/bin/v4l2loopback.sh rebuild

[Install]
WantedBy=multi-user.target
```

The important relationship is:

```text
ExecCondition
     │
     ▼
needs-rebuild
     │
 ┌───┴────┐
 │        │
exists  missing
 │        │
exit 1  exit 0
 │        │
 ▼        ▼
skip    ExecStart
           │
           ▼
         rebuild
```

---

## 5.4 Why does systemd show `status=1/FAILURE`?

You may see:

```text
ExecCondition=/usr/local/bin/v4l2loopback.sh needs-rebuild
(code=exited, status=1/FAILURE)
```

In this project that normally means:

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
```

The word `FAILURE` describes the condition command's non-zero exit status.

It does **not** mean that module compilation failed.

---

## 5.5 What does `Skipped due to exec-condition` mean?

You may see:

```text
v4l2loopback-rebuild.service:
Skipped due to 'exec-condition'.
```

For this service, this is normally a successful no-op:

```text
module already exists
→ rebuild not required
→ ExecStart skipped
```

---

## 5.6 How do I enable systemd integration?

Run:

```bash
sudo /usr/local/bin/v4l2loopback.sh enable-systemd
```

The command is idempotent:

```text
unit missing
    → create
    → daemon-reload
    → enable

unit exists + disabled
    → preserve
    → enable

unit exists + enabled
    → preserve
    → report already enabled
```

It also starts the service once immediately so the condition is tested without waiting for another reboot.

---

## 5.7 Does `enable-systemd` overwrite an existing service?

No.

If:

```text
/etc/systemd/system/v4l2loopback-rebuild.service
```

already exists, it is preserved.

The command reports that the unit already exists instead of recreating it.

---

## 5.8 How do I test the service without rebooting?

```bash
sudo systemctl start v4l2loopback-rebuild.service
```

Check:

```bash
systemctl status v4l2loopback-rebuild.service
```

Logs:

```bash
journalctl -u v4l2loopback-rebuild.service
```

Current boot only:

```bash
journalctl -b -u v4l2loopback-rebuild.service
```

---

## 5.9 How do I disable systemd integration?

```bash
sudo /usr/local/bin/v4l2loopback.sh disable-systemd
```

The command is state-aware:

```text
enabled + unit exists
    → disable
    → remove
    → daemon-reload

disabled + unit exists
    → remove
    → daemon-reload

enabled + unit missing
    → disable
    → daemon-reload

disabled + unit missing
    → nothing to do
```

It also clears the failed state only when one exists.

Disabling systemd does **not** uninstall `v4l2loopback`.

---

# 6. Kernel updates

## 6.1 What happens after a Fedora kernel update?

With systemd enabled:

```text
Fedora installs new kernel
        │
        ▼
new kernel-devel installed
        │
        ▼
reboot
        │
        ▼
systemd
        │
        ▼
needs-rebuild
        │
   ┌────┴────┐
   │         │
 exists    missing
   │         │
   ▼         ▼
 skip     compile
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

---

## 6.2 What happens on the following reboot?

If the previous rebuild succeeded, this file now exists:

```text
/lib/modules/<kernel>/updates/v4l2loopback.ko
```

The next boot therefore gives:

```text
needs-rebuild
    │
    ▼
exit 1
    │
    ▼
ExecStart skipped
```

No unnecessary compilation occurs.

---

# 7. BIOS and UEFI firmware updates

## 7.1 Do I need to reinstall after a BIOS update?

Usually no.

A firmware update normally does not require:

```text
genkey    → not needed
rebuild   → not needed solely because of BIOS update
reinstall → not needed
```

First check:

```bash
mokutil --sb-state
```

Then:

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

And verify the module:

```bash
modinfo v4l2loopback |
    grep -E '^(filename|signer|sig_key|sig_hashalgo):'
```

If everything is still present, no action is required.

---

## 7.2 What if the MOK disappears?

Some firmware updates may reset UEFI configuration or NVRAM.

If the MOK disappears but these files still exist:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

do **not** generate another key.

Re-enroll the existing certificate:

```bash
sudo mokutil --import \
    /var/lib/shim-signed/mok/v4l.der
```

Then reboot and complete MOK enrollment.

---

## 7.3 When should I generate a new key?

Only when:

* The original private key is gone.
* The certificate is gone and cannot be recovered.
* You deliberately want to rotate the signing key.

Decision tree:

```text
              BIOS/UEFI UPDATE
                     │
                     ▼
             check MOK enrollment
                     │
             ┌───────┴───────┐
             │               │
           exists          missing
             │               │
             ▼               ▼
         do nothing     keys still exist?
                            │
                      ┌─────┴─────┐
                      │           │
                     yes          no
                      │           │
                      ▼           ▼
               re-enroll DER    genkey
```

Keeping the existing key is preferable because previously built modules were signed with that key.

---

# 8. Reinstall and uninstall

## 8.1 What does `reinstall` do?

Conceptually:

```text
reinstall
    │
    ▼
uninstall
    │
    ▼
prepare source repository
    │
    ▼
restore configuration
    │
    ▼
dracut -f
    │
    ▼
rebuild
```

---

## 8.2 Should I remove the signing keys during reinstall?

Normally no.

Preserving:

```text
v4l.key
v4l.der
```

allows future modules to continue being signed with the same enrolled certificate.

Deleting them unnecessarily would require generating and enrolling another key.

---

## 8.3 What is the difference between `uninstall` and `disable-systemd`?

`disable-systemd` removes only automatic boot-time management.

```text
disable-systemd
    └── remove systemd integration
```

`uninstall` affects the actual module installation:

```text
uninstall
    ├── unload module
    ├── remove .ko files
    ├── remove configuration
    ├── optionally stage MOK deletion
    ├── optionally remove source
    └── optionally remove keys
```

---

# 9. Troubleshooting

## 9.1 What if the source repository is missing?

The expected location is:

```text
/usr/src/v4l2loopback
```

Clone it:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

Then:

```bash
sudo /usr/local/bin/v4l2loopback.sh rebuild
```

---

## 9.2 What if `kernel-devel` is missing?

Install:

```bash
sudo dnf install -y kernel-devel
```

Check:

```bash
rpm -q kernel-devel
```

---

## 9.3 What if the signing keys are missing?

Check:

```bash
sudo ls -l /var/lib/shim-signed/mok/
```

Expected:

```text
v4l.key
v4l.der
```

If they really do not exist:

```bash
sudo /usr/local/bin/v4l2loopback.sh genkey
```

---

## 9.4 Why do I get `Key was rejected by service`?

Check Secure Boot:

```bash
mokutil --sb-state
```

Check the enrolled MOK:

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

Check the module signer:

```bash
modinfo v4l2loopback |
    grep -E '^(signer|sig_key|sig_hashalgo):'
```

The module may be correctly signed but the certificate may no longer be enrolled or trusted.

---

## 9.5 Why does `/dev/video10` not exist?

Check:

```bash
lsmod | grep v4l2loopback
```

Then:

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

Then:

```bash
ls -l /dev/video*
```

---

## 9.6 Why can't I unload the module?

An application may be using `/dev/video10`.

Check:

```bash
sudo fuser -v /dev/video10
```

Close the relevant application and try:

```bash
sudo modprobe -r v4l2loopback
```

again.

---

## 9.7 How can I quickly diagnose the installation?

Running kernel:

```bash
uname -r
```

Installed kernel development packages:

```bash
rpm -q kernel-devel
```

Secure Boot:

```bash
mokutil --sb-state
```

MOK:

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

Module:

```bash
modinfo v4l2loopback
```

Loaded state:

```bash
lsmod | grep v4l2loopback
```

Virtual camera:

```bash
v4l2-ctl --list-devices
```

Rebuild condition:

```bash
sudo /usr/local/bin/v4l2loopback.sh needs-rebuild
echo $?
```

systemd:

```bash
systemctl status v4l2loopback-rebuild.service
systemctl is-enabled v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Remember:

```text
needs-rebuild:

0 → .ko missing → rebuild
1 → .ko exists  → skip
```

---

# 10. Design summary

The main design rule is:

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
              ┌───────┴───────┐
              │               │
         .ko EXISTS       .ko MISSING
              │               │
              ▼               ▼
           exit 1           exit 0
              │               │
              ▼               ▼
        skip rebuild       rebuild
                              │
                              ▼
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

The result is a deliberately simple workflow:

* No DNF hook.
* No systemd timer.
* No unnecessary rebuild at every boot.
* Only the newest installed kernel is considered.
* Existing modules are preserved.
* Missing modules are compiled and signed before installation.
* Secure Boot trust is handled through MOK.
* BIOS/UEFI updates normally require no action unless MOK enrollment is lost.
