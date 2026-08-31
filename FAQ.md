# v4l2loopback Manager for Fedora — FAQ


<!-- TOC START -->
## Table of Contents

- [Which kernel does the manager target?](#which-kernel-does-the-manager-target)
- [Why use the default boot kernel?](#why-use-the-default-boot-kernel)
- [Does the target kernel have to be running?](#does-the-target-kernel-have-to-be-running)
- [What if matching `kernel-devel` is missing?](#what-if-matching-kernel-devel-is-missing)
- [What does `needs-rebuild` check?](#what-does-needs-rebuild-check)
- [What do exit codes 0 and 1 mean?](#what-do-exit-codes-0-and-1-mean)
- [Why can systemd show `status=1/FAILURE`?](#why-can-systemd-show-status1failure)
- [What does "Skipped due to exec-condition" mean?](#what-does-skipped-due-to-exec-condition-mean)
- [What happens if the `.ko` exists but is unsigned?](#what-happens-if-the-ko-exists-but-is-unsigned)
- [What happens if it is signed by another key?](#what-happens-if-it-is-signed-by-another-key)
- [Does `rebuild` always compile?](#does-rebuild-always-compile)
- [Where are the keys?](#where-are-the-keys)
- [What does `status` check?](#what-does-status-check)
- [How do I check Secure Boot and MOK enrollment?](#how-do-i-check-secure-boot-and-mok-enrollment)
- [Why can `mokutil --test-key` say enrolled but return 1?](#why-can-mokutil---test-key-say-enrolled-but-return-1)
- [How do I inspect the target module?](#how-do-i-inspect-the-target-module)
- [What happens after `dnf upgrade` installs a new kernel?](#what-happens-after-dnf-upgrade-installs-a-new-kernel)
- [Is systemd executed at every boot?](#is-systemd-executed-at-every-boot)
- [Does the project use a DNF hook?](#does-the-project-use-a-dnf-hook)
- [Does `enable-systemd` overwrite an existing unit?](#does-enable-systemd-overwrite-an-existing-unit)
- [How do I test the service without rebooting?](#how-do-i-test-the-service-without-rebooting)
- [How do I disable it?](#how-do-i-disable-it)
- [Why might `grubby --default-kernel` need root?](#why-might-grubby-default-kernel-need-root)
- [Do BIOS/UEFI updates require a rebuild?](#do-biosuefi-updates-require-a-rebuild)
- [What if `/dev/video10` is missing?](#what-if-devvideo10-is-missing)
- [How do I remove everything managed locally?](#how-do-i-remove-everything-managed-locally)

<!-- TOC END -->

## Which kernel does the manager target?

The Fedora **default boot kernel**, not simply the newest installed
`kernel-devel`.

```bash
sudo grubby --default-kernel
```

The returned `/boot/vmlinuz-...` basename determines the exact kernel version
used by both `needs-rebuild` and `rebuild`.

## Why use the default boot kernel?

Because an installed kernel is not necessarily the kernel Fedora is configured
to boot. Using `grubby --default-kernel` keeps the module target aligned with
Fedora's boot configuration.

## Does the target kernel have to be running?

No. If the default boot kernel differs from `uname -r`, the manager builds and
signs the module for the default boot kernel but does not try to load that module
into the currently running kernel.

## What if matching `kernel-devel` is missing?

The manager stops. Install the exact matching package:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"
sudo dnf install "kernel-devel-$TARGET"
```

## What does `needs-rebuild` check?

It checks:

```text
/lib/modules/<default-boot-kernel>/updates/v4l2loopback.ko
```

and verifies its signer with `modinfo -F signer`.

It also checks MOK enrollment so trust problems can be reported separately.
Missing enrollment does not force a rebuild when the `.ko` already has the
expected signer.

A valid signer contains:

```text
V4L2Loopback Module Signing
```

## What do exit codes 0 and 1 mean?

```text
0 -> module is missing or signature is invalid
     rebuild is required

1 -> module exists and expected signature is present
     rebuild is not required
```

This inverted-looking behavior is deliberate because `needs-rebuild` is used by
systemd `ExecCondition=`.

## Why can systemd show `status=1/FAILURE`?

For an `ExecCondition=`, exit status `1` means the condition is false. Here that
means the module is already valid and `ExecStart=` should be skipped. It does
not mean compilation failed.

## What does "Skipped due to exec-condition" mean?

Normally:

```text
module exists
+ expected signer is present
-> needs-rebuild returns 1
-> ExecStart is skipped
```

That is the desired no-op path.

## What happens if the `.ko` exists but is unsigned?

`needs-rebuild` returns `0`. `rebuild` compiles a fresh module, signs it with the
project MOK and replaces the invalid module.

## What happens if it is signed by another key?

The same: it is treated as requiring rebuild because the signer does not match
`V4L2Loopback Module Signing`.

## Does `rebuild` always compile?

No. A manual `rebuild` independently validates the module. If the target `.ko`
already exists and has the expected signer, it returns without compiling.

## Where are the keys?

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

The private key should remain mode `0600`.

## What does `status` check?

Run:

```bash
v4l2loopback status
```

It reports the Fedora default boot kernel, Secure Boot state, local signing-key
files, MOK enrollment, target-module existence, module signer, and whether the
module is loaded when the target kernel is the running kernel.

A healthy setup ends with:

```text
✅ v4l2loopback signing state is ready.
```

## How do I check Secure Boot and MOK enrollment?

```bash
v4l2loopback status

mokutil --sb-state

mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

The manager's `status` command is the preferred combined check.

## Why can `mokutil --test-key` say enrolled but return 1?

On some Fedora/mokutil combinations, this command can print:

```text
/path/to/v4l.der is already enrolled
```

while still exiting with status `1`, for example when access to the kernel
trusted keyring fails.

The manager does not rely only on that exit status. It runs the test in the C
locale and checks the explicit `is already enrolled` result so an enrolled
certificate is not reported as missing.

## How do I inspect the target module?

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -k "$TARGET" v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

## What happens after `dnf upgrade` installs a new kernel?

Fedora normally makes the new kernel the default boot entry. At boot, the
systemd oneshot service asks `grubby` for the default kernel and checks that
kernel's module. Missing or invalid module -> rebuild. Valid module -> skip.

## Is systemd executed at every boot?

If `v4l2loopback-rebuild.service` is enabled, yes. It is a oneshot unit: it runs
the condition once during that boot. There is no timer and no periodic polling.

## Does the project use a DNF hook?

No. Kernel installation and module compilation are intentionally separated.

## Does `enable-systemd` overwrite an existing unit?

No. Existing dynamically generated units are preserved. To regenerate an older
unit after upgrading the manager:

```bash
sudo v4l2loopback disable-systemd
sudo v4l2loopback enable-systemd
```

## How do I test the service without rebooting?

```bash
sudo systemctl start v4l2loopback-rebuild.service
systemctl status v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

## How do I disable it?

```bash
sudo v4l2loopback disable-systemd
```

This removes automatic boot-time management; it does not itself uninstall the
kernel module.

## Why might `grubby --default-kernel` need root?

On some Fedora installations access to GRUB environment data is restricted.
The manager handles this by invoking `grubby` directly when already root and
through `sudo` otherwise. RPM/systemd execution is root-owned.

## Do BIOS/UEFI updates require a rebuild?

Usually no. First run:

```bash
v4l2loopback status
```

If the module exists and is correctly signed but the MOK enrollment was lost,
the module itself does not need rebuilding. Re-enroll the **existing**
certificate:

```bash
sudo v4l2loopback genkey
```

`genkey` preserves a complete existing key pair and imports the existing DER
certificate when enrollment is missing. Then reboot manually:

```bash
sudo reboot
```

Complete enrollment in the blue MOK Manager screen and run `v4l2loopback
status` again. Do not regenerate the key merely because firmware/BIOS changes
affected MOK enrollment.

## What if `/dev/video10` is missing?

Check:

```bash
lsmod | grep v4l2loopback
dmesg | grep -i v4l2loopback
v4l2-ctl --list-devices
```

Try loading:

```bash
sudo modprobe v4l2loopback \
    devices=1 video_nr=10 card_label=VirtualCam exclusive_caps=1
```

## How do I remove everything managed locally?

Start while the command still exists:

```bash
sudo v4l2loopback uninstall
sudo v4l2loopback disable-systemd
```

Then remove the RPM:

```bash
sudo dnf remove v4l2loopback-manager
```
