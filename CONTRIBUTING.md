# Contributing to v4l2loopback Manager

Thank you for your interest in contributing to `v4l2loopback-manager`.

This project provides Fedora-specific management, Secure Boot signing, RPM/COPR packaging, and optional systemd integration for the upstream `v4l2loopback` kernel module.

Contributions involving bug fixes, documentation, testing, packaging, and improvements to the manager are welcome.

---

## Table of Contents

- [Project Scope](#project-scope)
- [Development Requirements](#development-requirements)
- [Clone the Repository](#clone-the-repository)
- [Create a Branch](#create-a-branch)
- [Make Your Changes](#make-your-changes)
- [ShellCheck](#shellcheck)
- [Testing](#testing)
- [RPM Validation](#rpm-validation)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Reporting Bugs](#reporting-bugs)
- [Security Issues](#security-issues)

---

## Project Scope

`v4l2loopback-manager` does not maintain the upstream `v4l2loopback` kernel module itself.

The responsibilities are separated as follows:

```text
┌─────────────────────────────────────────────┐
│ hhlp/v4l2loopback                           │
│                                             │
│ Fedora management                           │
│ Secure Boot / MOK signing                   │
│ RPM / COPR packaging                        │
│ systemd integration                         │
│ rebuild / verification logic                │
│ documentation and testing                   │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│ upstream v4l2loopback                       │
│                                             │
│ Linux kernel module implementation          │
└─────────────────────────────────────────────┘
```

Problems in the actual kernel module implementation may need to be reported to the upstream `v4l2loopback` project.

---

## Development Requirements

A Fedora development system is recommended.

Install the main development tools:

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
    grubby \
    ShellCheck \
    rpm-build
```

For RPM testing, additional Fedora packaging tools may also be useful:

```bash
sudo dnf install -y \
    rpmdevtools \
    mock
```

---

## Clone the Repository

Clone your fork:

```bash
git clone git@github.com:<username>/v4l2loopback.git
cd v4l2loopback
```

Add the original repository as `upstream` if required:

```bash
git remote add upstream \
    https://github.com/hhlp/v4l2loopback.git
```

Verify:

```bash
git remote -v
```

Before starting new work:

```bash
git switch main
git pull --ff-only
```

---

## Create a Branch

Do not develop directly on `main`.

Use a short branch name describing the purpose of the change.

Recommended branch prefixes:

```text
feature/
bugfix/
hotfix/
docs/
test/
refactor/
chore/
release/
```

Examples:

```bash
git switch -c feature/improve-signature-check
```

```bash
git switch -c bugfix/kernel-selection
```

```bash
git switch -c docs/update-secure-boot
```

---

## Make Your Changes

Keep each change focused on one purpose.

Before submitting a Pull Request:

```text
change
  │
  ▼
ShellCheck
  │
  ▼
TEST.md
  │
  ▼
RPM validation
  │
  ▼
review git diff
  │
  ▼
commit
  │
  ▼
Pull Request
```

Avoid mixing unrelated refactoring, documentation changes, and functional changes in the same commit unless they are directly related.

---

## ShellCheck

Run ShellCheck against the manager:

```bash
shellcheck v4l2loopback.sh
```

A contribution modifying the shell script should not introduce new ShellCheck warnings.

Also perform a Bash syntax check:

```bash
bash -n v4l2loopback.sh
```

Both commands should complete successfully before committing.

---

## Testing

Follow the validation procedure documented in:

```text
TEST.md
```

At minimum, changes affecting manager behavior should verify the relevant commands.

For example:

```bash
sudo ./v4l2loopback.sh needs-rebuild
```

```bash
sudo ./v4l2loopback.sh rebuild
```

For systemd-related changes:

```bash
sudo ./v4l2loopback.sh enable-systemd

systemctl status v4l2loopback-rebuild.service
systemctl is-enabled v4l2loopback-rebuild.service
```

Inspect logs when appropriate:

```bash
journalctl -b -u v4l2loopback-rebuild.service
```

Clean up the test system when necessary:

```bash
sudo ./v4l2loopback.sh disable-systemd
```

Always consult `TEST.md` for the complete test procedure.

---

## RPM Validation

Changes affecting:

```text
v4l2loopback.spec
v4l2loopback.sh
README.md
FAQ.md
TEST.md
LICENSE
```

should be checked against the RPM packaging when relevant.

Perform a basic SPEC validation:

```bash
rpmspec -P v4l2loopback.spec >/dev/null
```

Inspect package metadata:

```bash
rpmspec -q v4l2loopback.spec
```

A local RPM build can be performed using an RPM build tree or Fedora `mock`.

For example:

```bash
mock --rebuild <source-rpm>
```

Do not commit generated RPM build artifacts.

Typical artifacts that must remain outside Git include:

```text
*.rpm
*.src.rpm
BUILD/
BUILDROOT/
RPMS/
SRPMS/
```

---

## Commit Messages

This project uses Conventional Commit-style messages.

General format:

```text
<type>: <description>
```

Recommended types:

| Type | Purpose |
|---|---|
| `feat` | New functionality |
| `fix` | Bug fix |
| `hotfix` | Urgent production fix |
| `docs` | Documentation |
| `test` | Tests |
| `refactor` | Internal code restructuring |
| `chore` | Maintenance |
| `ci` | Continuous integration |
| `build` | RPM/build-system changes |

Examples:

```text
feat: add module verification command
```

```text
fix: use Fedora default boot kernel
```

```text
docs: improve Secure Boot documentation
```

```text
ci: add ShellCheck workflow
```

Keep the first line concise and written in the imperative style where practical.

---

## Pull Requests

Before opening a Pull Request, verify:

- The branch is based on the current `main`.
- The change has a clear and limited purpose.
- `bash -n v4l2loopback.sh` succeeds when the script was modified.
- `shellcheck v4l2loopback.sh` succeeds when the script was modified.
- Relevant tests from `TEST.md` have been completed.
- RPM-related changes have been validated.
- Documentation has been updated when behavior changes.
- `CHANGELOG.md` has been updated when the change is user-visible.
- No generated RPMs, private keys, credentials, or local build artifacts are included.

Review the final diff:

```bash
git status
git diff main...HEAD
```

Then push the branch:

```bash
git push -u origin <branch>
```

and open a Pull Request against `main`.

---

## Reporting Bugs

A useful bug report should include enough Fedora and kernel information to reproduce the problem.

Useful diagnostic commands include:

```bash
cat /etc/fedora-release
uname -r
sudo grubby --default-kernel
mokutil --sb-state
rpm -q v4l2loopback-manager
rpm -q kernel kernel-devel
```

For module problems:

```bash
TARGET="$(sudo grubby --default-kernel)"
TARGET="${TARGET##*/}"
TARGET="${TARGET#vmlinuz-}"

modinfo -k "$TARGET" v4l2loopback
```

For systemd problems:

```bash
systemctl status v4l2loopback-rebuild.service
journalctl -b -u v4l2loopback-rebuild.service
```

Before posting logs publicly, inspect them for private or system-specific information that should not be disclosed.

---

## Security Issues

Do **not** open a public issue containing:

```text
/var/lib/shim-signed/mok/v4l.key
```

or any other private key, credential, secret, or sensitive security material.

Never attach the MOK private key to a bug report.

Security-sensitive issues should follow the procedure documented in:

```text
SECURITY.md
```

---

## Contribution Workflow

The complete development flow is:

```text
fork / clone
     │
     ▼
update main
     │
     ▼
create branch
     │
     ▼
make changes
     │
     ├── bash -n
     ├── ShellCheck
     ├── TEST.md
     └── RPM validation
     │
     ▼
review diff
     │
     ▼
commit
     │
     ▼
push
     │
     ▼
Pull Request
     │
     ▼
review / CI
     │
     ▼
merge
```

Thank you for helping improve `v4l2loopback-manager`.