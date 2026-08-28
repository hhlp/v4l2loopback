# 🎥 v4l2loopback Manager for Fedora

> Secure Boot-aware management of the upstream `v4l2loopback` kernel module on Fedora.

[![Fedora](https://img.shields.io/badge/Fedora-supported-blue?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![COPR](https://img.shields.io/badge/COPR-hhlp%2Fv4l2loopback-blue)](https://copr.fedorainfracloud.org/coprs/hhlp/v4l2loopback/)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/badge/release-v1.0.2-blue)](https://github.com/hhlp/v4l2loopback/releases/tag/v1.0.2)

`v4l2loopback-manager` builds, signs, installs, verifies, rebuilds, and removes the upstream [`v4l2loopback`](https://github.com/v4l2loopback/v4l2loopback) kernel module on Fedora systems, including systems with **UEFI Secure Boot enabled**.

The kernel module itself is **not distributed by this RPM**. It is built locally from the upstream source for Fedora's configured default boot kernel.

---

## ✨ Features

- Builds `v4l2loopback` locally for the Fedora default boot kernel.
- Detects the target kernel using `grubby --default-kernel`.
- Supports UEFI Secure Boot using a Machine Owner Key (MOK).
- Signs `v4l2loopback.ko` using the kernel `sign-file` utility.
- Verifies both module existence and expected certificate signer.
- Rebuilds only when the module is missing or has an invalid signature.
- Provides optional systemd integration for automatic boot-time verification.
- Keeps module options persistent through `modprobe.d`.
- Supports clean module uninstall and systemd removal.
- Designed for Fedora RPM/COPR installation.

---

## 🚀 Quick Start

### Install from COPR

```bash
sudo dnf copr enable hhlp/v4l2loopback
sudo dnf install v4l2loopback-manager
```

Verify the installation:

```bash
rpm -q v4l2loopback-manager
command -v v4l2loopback
v4l2loopback help
```

Generate the Secure Boot signing key:

```bash
sudo v4l2loopback genkey
```

After enrolling the MOK and rebooting, build and install the module:

```bash
sudo v4l2loopback rebuild
```

Optional automatic boot-time verification:

```bash
sudo v4l2loopback enable-systemd
```

---

## 🏗️ How It Works

The RPM provides the **manager**, not a precompiled kernel module.

```text
                    Fedora system
                         │
                         ▼
              v4l2loopback-manager
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    default kernel   Secure Boot     upstream source
       grubby            MOK        v4l2loopback.git
          │              │              │
          └──────────────┼──────────────┘
                         ▼
                  build module
                         │
                         ▼
                 sign module
                         │
                         ▼
       /lib/modules/<kernel>/updates/
                 v4l2loopback.ko
                         │
                         ▼
                      depmod
```

At boot, the optional systemd service performs a simple decision:

```text
             Fedora default boot kernel
                        │
                        ▼
              v4l2loopback.ko
                        │
                 ┌──────┴──────┐
                 │             │
              missing        exists
                 │             │
                 │             ▼
                 │        check signer
                 │         ┌───┴───┐
                 │         │       │
                 │       valid   invalid
                 │         │       │
                 ▼         ▼       ▼
              rebuild     skip   rebuild
```

---

<!-- TOC START -->
## 📚 Table of Contents

- [Features](#️-features)
- [Quick Start](#-quick-start)
- [How It Works](#️-how-it-works)
- [Version 1.0.2 Design](#version-102-design)
- [Requirements](#requirements)
- [RPM / COPR Installation](#rpm--copr-installation)
- [Commands](#commands)
- [Secure Boot Key](#secure-boot-key)
- [Source Tree](#source-tree)
- [Kernel Selection](#kernel-selection)
- [Rebuild Decision](#rebuild-decision)
- [systemd Integration](#systemd-integration)
- [Persistent Module Configuration](#persistent-module-configuration)
- [Verification](#verification)
- [Kernel Updates](#kernel-updates)
- [Removal](#removal)
- [Documentation](#documentation)
- [License](#license)

<!-- TOC END -->

---

## Version 1.0.2 Design

The manager deliberately has **no DNF hook and no systemd timer**.

The optional:

```text
v4l2loopback-rebuild.service
```

is a oneshot service evaluated at boot.

The target kernel is **the Fedora default boot kernel**, determined with:

```bash
sudo grubby --default-kernel
```

The same target is used by both:

```text
needs-rebuild
rebuild
```

The manager does **not** simply choose the numerically newest installed `kernel-devel`.

For the target kernel it expects:

```text
/lib/modules/<default-boot-kernel>/updates/v4l2loopback.ko
```

`needs-rebuild` validates two things:

1. The module exists.
2. `modinfo -F signer` contains `V4L2Loopback Module Signing`.

Its exit status is intentionally designed for systemd `ExecCondition=`:

```text
0 = module missing, unsigned, unreadable,
    or signed by another certificate
    → rebuild required

1 = module exists and has the expected signer
    → no rebuild required
```

> **Important:** exit status `1` from `needs-rebuild` is not an application failure. It means the systemd condition is false because the module is already valid.

---

## Requirements

The RPM installs the required runtime dependencies automatically.

For a manual/source installation, the required Fedora packages are:

```bash
sudo dnf install -y \
    git \
    gcc \
    make \
    kernel-devel \
    openssl \
    mokutil \
    dracut \
    kmod \
    systemd \
    grubby
```

Optional diagnostic tools:

```bash
sudo dnf install -y v4l-utils ShellCheck
```

---

## RPM / COPR Installation

Enable the COPR repository:

```bash
sudo dnf copr enable hhlp/v4l2loopback
```

Install:

```bash
sudo dnf install v4l2loopback-manager
```

The RPM installs the manager as:

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

### What the RPM installs

The RPM packages the management utility and documentation.

It deliberately does **not** ship a precompiled `v4l2loopback.ko`.

```text
RPM
 │
 ├── /usr/bin/v4l2loopback
 ├── README.md
 ├── FAQ.md
 ├── TEST.md
 └── LICENSE

v4l2loopback.ko
      ▲
      │
built locally for the
Fedora default boot kernel
```

This avoids coupling the package to one particular Fedora kernel build.

---

## Commands

Available commands:

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

Display built-in help:

```bash
v4l2loopback help
```

---

## Secure Boot Key

Generate the project MOK:

```bash
sudo v4l2loopback genkey
```

The manager uses:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

Certificate subject:

```text
CN=V4L2Loopback Module Signing
```

The private key:

```text
/var/lib/shim-signed/mok/v4l.key
```

must remain private and should **never be committed, uploaded, or attached to a GitHub issue**.

Complete MOK enrollment after reboot, then verify:

```bash
mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'
```

---

## Source Tree

The manager expects the upstream source at:

```text
/usr/src/v4l2loopback
```

Clone it when needed:

```bash
sudo git clone \
    https://github.com/v4l2loopback/v4l2loopback.git \
    /usr/src/v4l2loopback
```

The source comes from the upstream `v4l2loopback` project. This repository provides the Fedora management, Secure Boot, packaging, and systemd integration around it.

---

## Kernel Selection

Version `1.0.2` uses Fedora's configured **default boot kernel**.

Show it with:

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

and expects the corresponding kernel paths:

```text
/usr/src/kernels/7.1.10-200.fc44.x86_64
/lib/modules/7.1.10-200.fc44.x86_64
```

This distinction is important.

```text
newest installed kernel
          ≠
Fedora configured default boot kernel
```

The manager follows the kernel Fedora is configured to boot.

If `kernel-devel` for that kernel is missing, install the matching package before rebuilding.

---

## Rebuild Decision

The rebuild decision is:

```text
Fedora default boot kernel
          │
          ▼
expected v4l2loopback.ko
          │
     ┌────┴────┐
     │         │
   missing    exists
     │         │
     │         ▼
     │     check signer
     │      ┌──┴──┐
     │      │     │
     │    valid invalid
     │      │     │
     ▼      ▼     ▼
 rebuild   skip  rebuild
```

Run the condition manually:

```bash
sudo v4l2loopback needs-rebuild
echo $?
```

Interpretation:

```text
0 → rebuild required
1 → module already valid
```

Perform the build:

```bash
sudo v4l2loopback rebuild
```

`rebuild` independently checks the same target and signature. Therefore, a manual `rebuild` also avoids recompiling an already valid module.

If the module exists but is unsigned or signed by another certificate, it is rebuilt and replaced.

### Build pipeline

```text
make clean
    │
    ▼
make KERNELRELEASE=<default-boot-kernel>
    │
    ▼
kernel sign-file sha256
    │
    ▼
install v4l2loopback.ko
    │
    ▼
depmod -a <kernel>
```

The module is reloaded immediately only when:

```text
target kernel == uname -r
```

Otherwise, the module is prepared for the next boot into the target kernel.

---

## systemd Integration

Enable automatic boot-time checking:

```bash
sudo v4l2loopback enable-systemd
```

The manager generates:

```text
v4l2loopback-rebuild.service
```

with the equivalent logic:

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

The boot flow is:

```text
boot
 │
 ▼
v4l2loopback-rebuild.service
 │
 ▼
needs-rebuild
 │
 ├── exit 0 ──► ExecStart=rebuild
 │
 └── exit 1 ──► skip ExecStart
```

At every boot, systemd evaluates the condition.

Exit `1` from `needs-rebuild` means the module is already valid, so `ExecStart=` is intentionally skipped.

systemd may display:

```text
ExecCondition=... (code=exited, status=1/FAILURE)
```

followed by:

```text
Skipped due to 'exec-condition'
```

In this design that is an **expected false condition**, not a failed compilation or broken service.

Check the service:

```bash
systemctl status v4l2loopback-rebuild.service
systemctl is-enabled v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Disable and remove the dynamically generated unit:

```bash
sudo v4l2loopback disable-systemd
```

If upgrading from an older release whose generated unit already exists, `enable-systemd` preserves that file.

To regenerate its contents using the current version:

```bash
sudo v4l2loopback disable-systemd
sudo v4l2loopback enable-systemd
```

---

## Persistent Module Configuration

The manager uses:

```text
/etc/modprobe.d/v4l2loopback.conf
/etc/modules-load.d/v4l2loopback.conf
```

Default module options:

```text
devices=1 video_nr=10 card_label=VirtualCam exclusive_caps=1
```

These settings provide a persistent virtual camera configuration across boots.

---

## Verification

Determine the Fedora default boot kernel:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

echo "$TARGET"
```

Inspect the module:

```bash
modinfo -k "$TARGET" v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

Expected signer:

```text
V4L2Loopback Module Signing
```

For the currently running kernel:

```bash
lsmod | grep v4l2loopback
```

If `v4l-utils` is installed:

```bash
v4l2-ctl --list-devices
```

A normal installation should expose the configured virtual camera, by default:

```text
VirtualCam
```

---

## Kernel Updates

After:

```bash
sudo dnf upgrade
```

Fedora normally changes its configured default boot kernel to the newly installed kernel.

On the next boot:

```text
Fedora boot
    │
    ▼
systemd oneshot
    │
    ▼
grubby --default-kernel
    │
    ▼
check v4l2loopback.ko
    │
    ▼
check signer
    │
 ┌──┴───┐
 │      │
valid invalid/missing
 │      │
skip  rebuild
```

The manager therefore follows the kernel **Fedora is configured to boot**, rather than assuming that the highest installed `kernel-devel` is always the intended kernel.

There is deliberately:

- no DNF hook;
- no background timer;
- no unnecessary rebuild when the module is already valid.

---

## Removal

Because the manager creates local system state that does not belong directly to the RPM payload, cleanup should be explicit.

Recommended sequence:

```bash
sudo v4l2loopback uninstall
sudo v4l2loopback disable-systemd
sudo dnf remove v4l2loopback-manager
```

The RPM intentionally does **not** silently remove:

```text
MOK private/public keys
MOK enrollment state
/usr/src/v4l2loopback
locally built kernel modules
dynamically generated systemd state
```

This prevents an RPM removal from unexpectedly deleting locally generated Secure Boot material or kernel-module state.

The RPM displays a cleanup reminder during final package removal.

---

## Documentation

Additional project documentation:

| Document                             | Purpose                                          |
|--------------------------------------|--------------------------------------------------|
| [`FAQ.md`](FAQ.md)                   | Troubleshooting and frequently asked questions   |
| [`TEST.md`](TEST.md)                 | Validation and testing procedure                 |
| [`CHANGELOG.md`](CHANGELOG.md)       | Release history and notable changes              |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution workflow and development guidelines |
| [`SECURITY.md`](SECURITY.md)         | Security policy and vulnerability reporting      |
| [`LICENSE`](LICENSE)                 | GPL-3.0 license                                  |

---

## Project Scope

This project manages the build and installation of the upstream `v4l2loopback` module on Fedora.

```text
┌────────────────────────────────────────────┐
│ hhlp/v4l2loopback                          │
│                                            │
│ Fedora management                          │
│ RPM / COPR packaging                       │
│ Secure Boot / MOK signing                  │
│ systemd integration                        │
│ verification / rebuild logic               │
└───────────────────┬────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────┐
│ upstream v4l2loopback                      │
│                                            │
│ actual Linux kernel module source          │
└────────────────────────────────────────────┘
```

Issues related specifically to the upstream kernel module itself may need to be reported to the upstream `v4l2loopback` project.

---

## License

`v4l2loopback-manager` is distributed under the **GNU General Public License v3.0 only (`GPL-3.0-only`)**.

See [`LICENSE`](LICENSE) for the complete license text.

---

**Current release:** `v1.0.2`
**Platform:** Fedora Linux
**Manager:** `/usr/bin/v4l2loopback`
**Kernel target:** Fedora default boot kernel via `grubby --default-kernel`
