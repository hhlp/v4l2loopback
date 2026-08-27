# 🎥 v4l2loopback Manager for Fedora

`v4l2loopback-manager` builds, signs, installs and maintains the upstream
`v4l2loopback` kernel module on Fedora systems, including systems with Secure Boot.


<!-- TOC START -->
## Table of Contents

- [Version 1.0.2 design](#version-102-design)
- [Requirements](#requirements)
- [RPM / COPR installation](#rpm-copr-installation)
- [Commands](#commands)
- [Secure Boot key](#secure-boot-key)
- [Source tree](#source-tree)
- [Kernel selection](#kernel-selection)
- [Rebuild decision](#rebuild-decision)
- [systemd integration](#systemd-integration)
- [Persistent module configuration](#persistent-module-configuration)
- [Verification](#verification)
- [Kernel updates](#kernel-updates)
- [Removal](#removal)

<!-- TOC END -->

## Version 1.0.2 design

The manager deliberately has no DNF hook and no systemd timer. The optional
`v4l2loopback-rebuild.service` is a oneshot service run at boot.

The target kernel is **the Fedora default boot kernel**, determined with:

```bash
sudo grubby --default-kernel
```

The same target is used by both `needs-rebuild` and `rebuild`. The manager does
not simply choose the numerically newest installed `kernel-devel`.

For the target kernel it expects:

```text
/lib/modules/<default-boot-kernel>/updates/v4l2loopback.ko
```

`needs-rebuild` validates two things:

1. The module exists.
2. `modinfo -F signer` contains `V4L2Loopback Module Signing`.

Its exit status is intentionally suitable for systemd `ExecCondition=`:

```text
0 = module missing, unsigned, unreadable, or signed by another certificate
    -> rebuild required

1 = module exists and has the expected signer
    -> no rebuild required
```

## Requirements

```bash
sudo dnf install -y \
    git gcc make kernel-devel openssl mokutil dracut kmod systemd grubby
```

Optional diagnostics:

```bash
sudo dnf install -y v4l-utils ShellCheck
```

## RPM / COPR installation

```bash
sudo dnf copr enable hhlp/v4l2loopback
sudo dnf install v4l2loopback-manager
```

The RPM installs:

```text
/usr/bin/v4l2loopback
```

Verify:

```bash
rpm -q v4l2loopback-manager
rpm -qf /usr/bin/v4l2loopback
command -v v4l2loopback
v4l2loopback help
```

## Commands

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

## Secure Boot key

Generate the project MOK:

```bash
sudo v4l2loopback genkey
```

Files:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

Certificate subject:

```text
CN=V4L2Loopback Module Signing
```

Complete MOK enrollment after reboot, then verify:

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

## Source tree

The manager expects upstream source at:

```text
/usr/src/v4l2loopback
```

Clone it when needed:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

## Kernel selection

Show Fedora's configured default kernel:

```bash
sudo grubby --default-kernel
```

Example:

```text
/boot/vmlinuz-7.1.10-200.fc44.x86_64
```

The manager extracts:

```text
7.1.10-200.fc44.x86_64
```

and requires:

```text
/usr/src/kernels/7.1.10-200.fc44.x86_64
/lib/modules/7.1.10-200.fc44.x86_64
```

If `kernel-devel` for that kernel is missing, install the matching package.

## Rebuild decision

```text
Fedora default boot kernel
          |
          v
expected v4l2loopback.ko
          |
     +----+----+
     |         |
   missing    exists
     |         |
     |       check signer
     |         |
     |    +----+----+
     |    |         |
     |  valid     invalid
     |    |         |
     v    v         v
 rebuild skip     rebuild
```

Run manually:

```bash
sudo v4l2loopback needs-rebuild
echo $?

sudo v4l2loopback rebuild
```

`rebuild` independently checks the same target and signature, so a manual
`rebuild` also avoids recompiling a valid module. If the module exists but is
unsigned or signed by another certificate, it is rebuilt and replaced.

The build sequence is:

```text
make clean
-> make KERNELRELEASE=<default-boot-kernel>
-> sign-file sha256
-> install .ko
-> depmod -a <kernel>
```

The module is reloaded immediately only when the target kernel equals `uname -r`.
Otherwise it is prepared for the next boot.

## systemd integration

Enable:

```bash
sudo v4l2loopback enable-systemd
```

Generated unit:

```ini
[Unit]
Description=Ensure v4l2loopback is available for Fedora default boot kernel
Documentation=https://github.com/hhlp/v4l2loopback
After=local-fs.target
ConditionPathExists=/usr/bin/v4l2loopback

[Service]
Type=oneshot
ExecCondition=/usr/bin/v4l2loopback needs-rebuild
ExecStart=/usr/bin/v4l2loopback rebuild

[Install]
WantedBy=multi-user.target
```

At every boot systemd evaluates the condition. Exit `1` from `needs-rebuild`
means the module is already valid, so `ExecStart=` is intentionally skipped.
systemd may display `status=1/FAILURE` for the condition process; in this design
that is the expected false condition, not a failed compilation.

Check:

```bash
systemctl status v4l2loopback-rebuild.service
systemctl is-enabled v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Disable and remove the dynamically generated unit:

```bash
sudo v4l2loopback disable-systemd
```

If upgrading from an older release whose generated unit already exists,
`enable-systemd` preserves that file. Run `disable-systemd` followed by
`enable-systemd` if you want to regenerate the unit text with the 1.0.2
description.

## Persistent module configuration

The manager uses:

```text
/etc/modprobe.d/v4l2loopback.conf
/etc/modules-load.d/v4l2loopback.conf
```

Default options:

```text
devices=1 video_nr=10 card_label=VirtualCam exclusive_caps=1
```

## Verification

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -k "$TARGET" v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

Expected signer:

```text
V4L2Loopback Module Signing
```

For the running kernel:

```bash
lsmod | grep v4l2loopback
v4l2-ctl --list-devices
```

## Kernel updates

After `dnf upgrade`, Fedora normally changes the default boot kernel to the new
kernel. On the next boot the oneshot service asks `grubby` for that configured
default, checks the corresponding module and signer, and rebuilds only if needed.

This means the manager follows the kernel Fedora is configured to boot, rather
than assuming that the highest installed `kernel-devel` is always the intended
kernel.

## Removal

Before removing the RPM, when cleanup is desired:

```bash
sudo v4l2loopback uninstall
sudo v4l2loopback disable-systemd
sudo dnf remove v4l2loopback-manager
```

The RPM intentionally does not silently remove locally generated signing keys,
MOK state, source trees, locally built modules, or dynamically generated systemd
state.

See `FAQ.md` and `TEST.md` for troubleshooting and validation.
