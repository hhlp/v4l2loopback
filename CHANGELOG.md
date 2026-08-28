# Changelog

All notable changes to `v4l2loopback-manager` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Professional project documentation.
- Project changelog.
- Contribution guidelines.
- Security policy.

---

## [1.0.2] - 2026-08-28

### Fixed

- Changed target kernel selection to use Fedora's configured default boot
  kernel.
- The manager now determines the target kernel using
  `grubby --default-kernel`.
- `needs-rebuild` and `rebuild` now use the same target kernel selection
  logic.
- Avoided incorrectly assuming that the numerically newest installed kernel
  is necessarily Fedora's intended boot kernel.

---

## [1.0.1] - 2026-08-27

### Fixed

- Changed the installed Fedora manager command to:

  ```text
  /usr/bin/v4l2loopback
  ```

- Updated the generated systemd service to use the manager from `/usr/bin`.

---

## [1.0.0] - 2026-08-27

### Added

- Initial Fedora RPM packaging for `v4l2loopback-manager`.
- Fedora COPR packaging support.
- Secure Boot-aware `v4l2loopback` management.
- Local compilation of the upstream `v4l2loopback` kernel module.
- Machine Owner Key (MOK) generation.
- Kernel module signing using the kernel `sign-file` utility.
- Module signature verification.
- `needs-rebuild` condition checking.
- Kernel module rebuild and reinstall operations.
- Module uninstall support.
- Optional systemd boot-time rebuild verification.
- Persistent `modprobe.d` module configuration.
- Persistent `modules-load.d` configuration.
- Project documentation and testing instructions.

### Design

The RPM provides the management utility but does not distribute a precompiled
`v4l2loopback.ko`.

The kernel module is built locally from the upstream `v4l2loopback` source for
the target Fedora kernel.

---

## Version History

```text
v1.0.0
   │
   │  Fedora RPM and COPR packaging
   ▼
v1.0.1
   │
   │  Fedora manager moved to /usr/bin
   ▼
v1.0.2
   │
   │  Fedora default boot kernel selection
   ▼
Unreleased
```

---

[Unreleased]: https://github.com/hhlp/v4l2loopback/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/hhlp/v4l2loopback/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/hhlp/v4l2loopback/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/hhlp/v4l2loopback/releases/tag/v1.0.0
