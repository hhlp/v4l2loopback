# Changelog

All notable changes to `v4l2loopback-manager` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

### Changed

### Fixed

### Security

---

## [1.0.4] - 2026-08-31

### Added

- Added the `status` command to report the Fedora default boot kernel, Secure
  Boot state, signing-key files, MOK enrollment, target-module presence,
  module signer, and running-kernel module state.
- Added explicit MOK enrollment verification before deciding whether a valid
  signed module requires attention.
- Added recovery guidance for BIOS/UEFI or firmware changes that can leave the
  existing signing certificate unenrolled.

### Changed

- `genkey` now preserves an existing complete signing key pair and reuses the
  existing DER certificate when MOK enrollment must be restored.
- MOK enrollment detection now handles Fedora/mokutil combinations where
  `mokutil --test-key` can print `is already enrolled` while still returning
  exit status `1`.
- `needs-rebuild` now distinguishes module validity from MOK trust: a module
  that already exists and has the expected signer is not rebuilt merely
  because its MOK enrollment is missing.
- `rebuild` now avoids unnecessary compilation when the module is already
  correctly signed and instead directs the user to re-enroll the existing
  certificate when needed.
- MOK recovery instructions now make the reboot step explicitly manual.

### Fixed

- Fixed false `Signing certificate is NOT enrolled` reports caused by relying
  only on the exit status of `mokutil --test-key`.
- Avoided regenerating signing keys as a response to lost MOK enrollment.



---

## [1.0.3] - 2026-08-28

### Added

* Added `CHANGELOG.md` to maintain a structured release history following
  Keep a Changelog conventions.
* Added `CONTRIBUTING.md` with development requirements, contribution workflow,
  testing guidelines, RPM validation, commit conventions, and security guidance.
* Added `SECURITY.md` documenting supported versions, private vulnerability
  reporting, MOK private-key handling, privileged operations, and the project
  security model.
* Added GitHub Issue Forms for bug reports and feature requests.
* Added GitHub issue configuration with dedicated links for private security
  reports and upstream `v4l2loopback` issues.
* Added a Pull Request template with testing, packaging, documentation, and
  security checklists.
* Added a GitHub Actions ShellCheck workflow for Bash syntax validation and
  static analysis.
* Added a GitHub Actions RPM build workflow to validate the SPEC, build SRPM
  and binary RPM packages, rebuild from the generated SRPM, and inspect the
  resulting package.
* Added RPM artifact validation for the installed manager path and packaged
  documentation.
* Added release-preparation tooling for synchronizing release information
  between `CHANGELOG.md` and `v4l2loopback.spec`.
* Added automatic GitHub Release support based on version tags and
  `CHANGELOG.md` release entries.
* Added `example.work-flow.md` as a example of a Work-Flow for future use.

### Changed

* Expanded `README.md` into the main project landing page with installation,
  architecture, Secure Boot, kernel-selection, rebuild, systemd, verification,
  removal, and project-scope documentation.
* Added project flow diagrams describing the module build, signing, rebuild,
  systemd, and responsibility-boundary workflows.
* Improved project documentation navigation with tables of contents and
  cross-document references.
* Extended ShellCheck coverage to include project maintenance and release
  scripts.
* Extended RPM CI triggers to include SPEC, changelog, release tooling, and
  workflow changes.
* Improved RPM CI validation to verify package metadata, expected files,
  generated SRPMs, binary RPMs, and SRPM rebuildability.
* Standardized release preparation around `CHANGELOG.md` as the primary
  human-maintained source of release changes.
* Prepared the project for automated GitHub Release and COPR release workflows.

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
v1.0.3
   │
   │  Documentation, CI and release automation
   ▼
Unreleased
```

---

[Unreleased]: https://github.com/hhlp/v4l2loopback/compare/v1.0.4...HEAD
[1.0.4]: https://github.com/hhlp/v4l2loopback/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/hhlp/v4l2loopback/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/hhlp/v4l2loopback/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/hhlp/v4l2loopback/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/hhlp/v4l2loopback/releases/tag/v1.0.0
