# v4l2loopback-manager — Test Plan

This test plan validates the default-boot-kernel selection, signature-aware
rebuild decision, MOK enrollment handling, `status` reporting, systemd
integration, Secure Boot recovery workflow and RPM packaging.

> Some tests intentionally move or replace a kernel module. Run them only on a
> test machine and keep a recovery path available.


<!-- TOC START -->
## Table of Contents

- [1. Static checks](#1-static-checks)
- [2. Confirm target-kernel calculation](#2-confirm-target-kernel-calculation)
- [3. Confirm manager help](#3-confirm-manager-help)
- [4. Status command](#4-status-command)
- [5. MOK enrollment detection](#5-mok-enrollment-detection)
- [6. Valid module: `needs-rebuild` must return 1](#6-valid-module-needs-rebuild-must-return-1)
- [7. Missing module: `needs-rebuild` must return 0](#7-missing-module-needs-rebuild-must-return-0)
- [8. Invalid/unsigned module: `needs-rebuild` must return 0](#8-invalidunsigned-module-needs-rebuild-must-return-0)
- [9. Manual rebuild must skip a valid module](#9-manual-rebuild-must-skip-a-valid-module)
- [10. Running kernel differs from default kernel](#10-running-kernel-differs-from-default-kernel)
- [11. systemd unit generation](#11-systemd-unit-generation)
- [12. systemd valid-module path](#12-systemd-valid-module-path)
- [13. systemd missing-module path](#13-systemd-missing-module-path)
- [14. systemd invalid-signature path](#14-systemd-invalid-signature-path)
- [15. Reboot test](#15-reboot-test)
- [16. Secure Boot validation](#16-secure-boot-validation)
- [17. BIOS / UEFI / firmware MOK recovery](#17-bios--uefi--firmware-mok-recovery)
- [18. Virtual camera](#18-virtual-camera)
- [19. RPM spec checks](#19-rpm-spec-checks)
- [20. Build RPM](#20-build-rpm)
- [21. RPM install/upgrade](#21-rpm-installupgrade)
- [22. Upgrade scriptlet behavior](#22-upgrade-scriptlet-behavior)
- [23. Final removal warning](#23-final-removal-warning)

<!-- TOC END -->

## 1. Static checks

```bash
bash -n v4l2loopback.sh
shellcheck v4l2loopback.sh
```

Expected: no syntax errors. Review any ShellCheck findings before release.

## 2. Confirm target-kernel calculation

```bash
sudo grubby --default-kernel

TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"
printf 'TARGET=%s\n' "$TARGET"

test -d "/lib/modules/$TARGET"
test -d "/usr/src/kernels/$TARGET"
```

Expected: `TARGET` exactly matches the version in the default `vmlinuz` path.

## 3. Confirm manager help

```bash
sudo install -m 755 v4l2loopback.sh /usr/bin/v4l2loopback
v4l2loopback help
```

Expected: help says **Fedora default boot kernel** and documents signature-aware
`needs-rebuild`.

## 4. Status command

```bash
v4l2loopback status
```

Expected on a healthy Secure Boot installation:

```text
Signing certificate is enrolled.
Module exists.
Module is signed with the expected certificate.
v4l2loopback signing state is ready.
```

If the default boot kernel is also the running kernel and the module is loaded,
the status output should also report that `v4l2loopback` is loaded.

## 5. MOK enrollment detection

Verify the certificate directly:

```bash
sudo env LC_ALL=C mokutil     --test-key /var/lib/shim-signed/mok/v4l.der 2>&1
```

An enrolled certificate should report:

```text
/var/lib/shim-signed/mok/v4l.der is already enrolled
```

Do **not** require exit status `0` from `mokutil --test-key` for this test.
Some Fedora/mokutil combinations can print the enrolled result while returning
status `1`.

Now verify the manager:

```bash
v4l2loopback status
```

Expected:

```text
🔏 MOK enrollment:
   ✅ Signing certificate is enrolled.
```

This guards against the false-negative enrollment bug.

## 6. Valid module: `needs-rebuild` must return 1

First build a valid module:

```bash
sudo v4l2loopback rebuild
```

Then:

```bash
sudo v4l2loopback needs-rebuild
rc=$?
echo "rc=$rc"
```

Expected:

```text
module exists and is correctly signed
rc=1
```

Verify signer:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -F signer \
    "/lib/modules/$TARGET/updates/v4l2loopback.ko"
```

Expected output contains:

```text
V4L2Loopback Module Signing
```

## 7. Missing module: `needs-rebuild` must return 0

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"
MOD="/lib/modules/$TARGET/updates/v4l2loopback.ko"

sudo mv "$MOD" "$MOD.test-backup"

set +e
sudo v4l2loopback needs-rebuild
rc=$?
set -e
echo "rc=$rc"
```

Expected: `rc=0`.

Restore before continuing if you are not testing rebuild:

```bash
sudo mv "$MOD.test-backup" "$MOD"
sudo depmod -a "$TARGET"
```

Or test rebuild:

```bash
sudo v4l2loopback rebuild
test -f "$MOD"
modinfo -F signer "$MOD"
```

Expected: module recreated and signer is correct.

## 8. Invalid/unsigned module: `needs-rebuild` must return 0

Use a controlled test copy only. Save the valid module first:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"
MOD="/lib/modules/$TARGET/updates/v4l2loopback.ko"

sudo cp -a "$MOD" "$MOD.valid-backup"
```

Replace `$MOD` with a known unsigned test build of `v4l2loopback.ko`, run
`depmod`, then:

```bash
set +e
sudo v4l2loopback needs-rebuild
rc=$?
set -e
echo "rc=$rc"
```

Expected: `rc=0` and output reports an unsigned/invalid signer.

Then:

```bash
sudo v4l2loopback rebuild
modinfo -F signer "$MOD"
```

Expected: rebuild replaces the invalid module and signer contains
`V4L2Loopback Module Signing`.

If needed, restore:

```bash
sudo mv -f "$MOD.valid-backup" "$MOD"
sudo depmod -a "$TARGET"
```

## 9. Manual rebuild must skip a valid module

```bash
sudo v4l2loopback rebuild
```

Expected: manager detects the existing valid signer and exits without `make`.

## 10. Running kernel differs from default kernel

Compare:

```bash
uname -r
sudo grubby --default-kernel
```

When they differ, run:

```bash
sudo v4l2loopback rebuild
```

Expected: module is prepared for the default boot kernel and the manager does
not try to load that module into the current kernel.

## 11. systemd unit generation

If an old generated unit exists, regenerate it:

```bash
sudo v4l2loopback disable-systemd
sudo v4l2loopback enable-systemd
```

Inspect:

```bash
systemctl cat v4l2loopback-rebuild.service
```

Expected key lines:

```ini
Description=Ensure v4l2loopback is available for Fedora default boot kernel
ConditionPathExists=/usr/bin/v4l2loopback
ExecCondition=/usr/bin/v4l2loopback needs-rebuild
ExecStart=/usr/bin/v4l2loopback rebuild
```

## 12. systemd valid-module path

With a valid module:

```bash
sudo systemctl start v4l2loopback-rebuild.service
systemctl status v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Expected: `ExecCondition` returns `1`, `ExecStart` is skipped, and systemd may
show `status=1/FAILURE` for the condition process. This is expected.

## 13. systemd missing-module path

Back up/remove the target module as in test 5, then:

```bash
sudo systemctl start v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Expected: `needs-rebuild` returns `0`; `ExecStart` runs; module is compiled,
signed, installed and `depmod` runs.

## 14. systemd invalid-signature path

Place an unsigned/wrong-signer test module as in test 6, then:

```bash
sudo systemctl start v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Expected: condition returns `0` and rebuild replaces the module with a correctly
signed one.

## 15. Reboot test

```bash
sudo systemctl enable v4l2loopback-rebuild.service
sudo reboot
```

After boot:

```bash
journalctl -b -u v4l2loopback-rebuild.service
sudo v4l2loopback needs-rebuild
echo $?
```

Expected after successful preparation: `needs-rebuild` returns `1`.

## 16. Secure Boot validation

```bash
mokutil --sb-state

mokutil --list-enrolled |
    grep -A5 -B5 'V4L2Loopback Module Signing'

modinfo v4l2loopback |
    grep -E '^(filename|version|signer|sig_key|sig_hashalgo):'
```

Expected: Secure Boot state is known, MOK is enrolled when Secure Boot is used,
and signer is correct.

## 17. BIOS / UEFI / firmware MOK recovery

This test is destructive to enrollment state and should only be performed on a
system where MOK enrollment can be safely restored.

Before changing enrollment, record hashes of the existing key pair:

```bash
sudo sha256sum     /var/lib/shim-signed/mok/v4l.key     /var/lib/shim-signed/mok/v4l.der
```

When the existing certificate is not enrolled but both local key files still
exist, run:

```bash
sudo v4l2loopback genkey
```

Expected:

- the existing private key is preserved;
- the existing DER certificate is preserved;
- no new key pair is generated;
- the existing DER certificate is staged with `mokutil --import`;
- the script instructs the user to reboot manually.

Recheck the file hashes before reboot. They must be unchanged.

After manually rebooting and completing enrollment in MOK Manager:

```bash
v4l2loopback status
```

Expected: MOK is enrolled and the signing state is ready. If the target module
was already correctly signed before the enrollment recovery, no module rebuild
should have been required.

## 18. Virtual camera

```bash
lsmod | grep v4l2loopback
v4l2-ctl --list-devices
v4l2-ctl --device=/dev/video10 --all
```

Expected: `VirtualCam` is available as configured.

## 19. RPM spec checks

```bash
rpmspec -P v4l2loopback-manager.spec >/dev/null
rpmspec -q v4l2loopback-manager.spec
```

Expected: the SPEC parses successfully and reports the version currently
declared in `v4l2loopback.spec`.

Confirm runtime dependency:

```bash
rpmspec -P v4l2loopback-manager.spec | grep -E '^Requires:.*grubby'
```

## 20. Build RPM

```bash
spectool -g -R v4l2loopback-manager.spec
rpmbuild -ba v4l2loopback-manager.spec
```

Or build through COPR.

Expected: successful noarch RPM.

## 21. RPM install/upgrade

```bash
sudo dnf install ./v4l2loopback-manager-*.noarch.rpm

rpm -q v4l2loopback-manager
rpm -qf /usr/bin/v4l2loopback
/usr/bin/v4l2loopback help
```

Expected: command is RPM-owned and executable.

## 22. Upgrade scriptlet behavior

Upgrade from the previous released RPM to the candidate RPM.

Expected: `%preun` cleanup warning is **not** shown for the package upgrade,
because `$1 != 0`.

## 23. Final removal warning

```bash
sudo dnf remove v4l2loopback-manager
```

Expected: `%preun` prints the cleanup reminder before final removal. The RPM does
not silently delete local MOK state, signing keys, source, built modules or the
dynamically generated systemd unit.

For a clean removal test, execute before DNF removal:

```bash
sudo v4l2loopback uninstall
sudo v4l2loopback disable-systemd
```
