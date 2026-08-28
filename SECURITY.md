# Security Policy

Security is an important part of `v4l2loopback-manager` because the project interacts with:

- UEFI Secure Boot.
- Machine Owner Keys (MOK).
- Private signing keys.
- Linux kernel modules.
- Kernel module signing.
- Root privileges.
- systemd services.
- Files under `/usr/src` and `/lib/modules`.

Please follow the guidelines below when reporting security issues or sharing diagnostic information.

---

## Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [What Should Be Reported Privately](#what-should-be-reported-privately)
- [MOK Private Key Security](#mok-private-key-security)
- [Safe Diagnostic Information](#safe-diagnostic-information)
- [Root Privileges](#root-privileges)
- [Kernel Module Security](#kernel-module-security)
- [Upstream Security Issues](#upstream-security-issues)
- [Security Recommendations](#security-recommendations)

---

## Supported Versions

Security fixes are normally applied to the latest release.

| Version | Supported |
|---|---|
| `1.0.2` | ✅ |
| `1.0.1` | ❌ |
| `1.0.0` | ❌ |

Users are encouraged to run the latest available release.

Check the installed version with:

```bash
rpm -q v4l2loopback-manager
```

---

## Reporting a Vulnerability

Please **do not open a public GitHub issue** for a vulnerability that could expose users to security risks.

Examples include:

- Privilege escalation.
- Command injection.
- Unsafe handling of root-controlled operations.
- Arbitrary file overwrite or deletion.
- Unsafe path handling.
- Signature verification bypass.
- Secure Boot bypass related to the manager.
- Private-key disclosure.
- Unsafe systemd service generation.
- Unexpected execution of untrusted code with root privileges.

Use GitHub's private vulnerability reporting mechanism when it is available for the repository.

When reporting a vulnerability, include:

```text
v4l2loopback-manager version
Fedora version
kernel version
Secure Boot state
affected command
steps to reproduce
expected behavior
actual behavior
security impact
```

Please provide enough information to reproduce the issue without including secrets or private keys.

---

## What Should Be Reported Privately

Security-sensitive reports should be private when they involve:

```text
privilege escalation
command injection
arbitrary command execution
signature verification bypass
Secure Boot bypass
unsafe root operations
private-key exposure
unsafe file permissions
arbitrary file modification
systemd privilege problems
```

Ordinary bugs that do not have a security impact may be reported through the normal public issue tracker.

---

## MOK Private Key Security

The manager uses the following signing material:

```text
/var/lib/shim-signed/mok/v4l.key
/var/lib/shim-signed/mok/v4l.der
```

The most important file is:

```text
/var/lib/shim-signed/mok/v4l.key
```

This is the **private signing key**.

### Never publish the private key

Do not:

```text
commit it to Git
push it to GitHub
attach it to an issue
paste it into a discussion
include it in diagnostic archives
send it through public chat
store it in a public backup
```

The private key must remain private to the machine or administrator that owns it.

### Public certificate

The corresponding:

```text
/var/lib/shim-signed/mok/v4l.der
```

is the public certificate used for MOK enrollment.

It does not contain the private signing key.

Nevertheless, diagnostic reports should include only information that is actually required to investigate the problem.

### Verify permissions

Check the signing material with:

```bash
sudo ls -l /var/lib/shim-signed/mok/v4l.key
sudo ls -l /var/lib/shim-signed/mok/v4l.der
```

The private key should not be readable by ordinary users.

Never change its permissions merely to make debugging easier.

---

## Safe Diagnostic Information

The following information is normally appropriate for a public bug report:

```bash
cat /etc/fedora-release
uname -r
sudo grubby --default-kernel
mokutil --sb-state
rpm -q v4l2loopback-manager
rpm -q kernel kernel-devel
```

Module metadata can normally be inspected with:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -k "$TARGET" v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

systemd diagnostics may include:

```bash
systemctl status v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Before publishing command output, inspect it manually.

Remove information that is unrelated to the bug and that could reveal sensitive local system details.

### Never include

Do not publish:

```text
private signing keys
passwords
authentication tokens
API keys
SSH private keys
GitHub tokens
complete credential files
unrelated private system information
```

---

## Root Privileges

Several manager operations require root privileges because they modify kernel and system configuration.

Examples include:

```text
/usr/src/v4l2loopback
/lib/modules/<kernel>/updates/
/etc/modprobe.d/
/etc/modules-load.d/
/etc/systemd/system/
/var/lib/shim-signed/mok/
```

Commands such as:

```bash
sudo v4l2loopback genkey
sudo v4l2loopback rebuild
sudo v4l2loopback reinstall
sudo v4l2loopback uninstall
sudo v4l2loopback enable-systemd
sudo v4l2loopback disable-systemd
```

therefore operate with elevated privileges.

Do not run modified or untrusted copies of `v4l2loopback.sh` as root.

Before running development versions with `sudo`, review the changes:

```bash
git diff
```

and verify the repository state:

```bash
git status
```

---

## Kernel Module Security

Kernel modules execute inside the Linux kernel and therefore operate with very high privileges.

`v4l2loopback-manager` builds the module from the upstream `v4l2loopback` source tree and signs the resulting module for Secure Boot.

The simplified trust chain is:

```text
upstream source
      │
      ▼
local compilation
      │
      ▼
v4l2loopback.ko
      │
      ▼
MOK private key
      │
      ▼
signed module
      │
      ▼
kernel verification
      │
      ▼
module loading
```

Signing a kernel module confirms that it was signed by a trusted key.

It does **not** prove that the source code itself is free from vulnerabilities.

Users should therefore obtain the module source from the legitimate upstream repository and keep both Fedora and the upstream project updated.

---

## Upstream Security Issues

This repository manages Fedora integration around the upstream `v4l2loopback` project.

The responsibility boundary is:

```text
hhlp/v4l2loopback
        │
        ├── Fedora management
        ├── Secure Boot signing
        ├── RPM / COPR packaging
        ├── systemd integration
        └── rebuild / verification logic

upstream v4l2loopback
        │
        └── Linux kernel module implementation
```

A vulnerability in:

```text
v4l2loopback-manager
RPM packaging
MOK handling
signature verification
systemd integration
privileged manager operations
```

belongs to this project.

A vulnerability in the actual `v4l2loopback` kernel module implementation should normally be reported to the upstream project following its security-reporting procedure.

If the responsibility is unclear, report the issue privately rather than publishing potentially sensitive vulnerability details.

---

## Security Recommendations

Users should:

1. Keep Fedora fully updated.
2. Keep `v4l2loopback-manager` updated.
3. Protect the MOK private key.
4. Never copy the private signing key to public or shared locations.
5. Obtain `v4l2loopback` source from the legitimate upstream project.
6. Review development changes before executing them as root.
7. Keep Secure Boot enabled when it is part of the system's security policy.
8. Investigate unexpected changes to the module signer.
9. Avoid loading unsigned or unexpectedly signed kernel modules.
10. Remove obsolete local signing keys securely when they are no longer required.

Check the expected module signer with:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -F signer -k "$TARGET" v4l2loopback
```

The expected signer for the default project configuration is:

```text
V4L2Loopback Module Signing
```

An unexpected signer should be investigated before loading the module.

---

## Security Model Summary

```text
                 Fedora Secure Boot
                         │
                         ▼
                   enrolled MOK
                         │
            ┌────────────┴────────────┐
            │                         │
      private key                public cert
        v4l.key                    v4l.der
            │                         │
            ▼                         ▼
       sign module              MOK enrollment
            │
            └────────────┬────────────┘
                         ▼
                  v4l2loopback.ko
                         │
                         ▼
                  kernel verifies
                         │
                    ┌────┴────┐
                    │         │
                  valid     invalid
                    │         │
                    ▼         ▼
                 allowed   rejected
```

The private signing key is the most sensitive project-generated security asset.

**Never publish `v4l.key`.**