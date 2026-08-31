Name:           v4l2loopback-manager
Version:        1.0.3
Release:        1%{?dist}
Summary:        Secure Boot manager for v4l2loopback on Fedora

License:        GPL-3.0-only
URL:            https://github.com/hhlp/v4l2loopback
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

BuildArch:      noarch

Requires:       bash
Requires:       git
Requires:       gcc
Requires:       make
Requires:       kernel-devel
Requires:       openssl
Requires:       mokutil
Requires:       dracut
Requires:       kmod
Requires:       systemd
Requires:       grubby

%description
v4l2loopback-manager is a Fedora management utility for building,
signing, installing, rebuilding, and removing the v4l2loopback
kernel module.

It supports Secure Boot using a Machine Owner Key (MOK) and can
optionally create and enable a systemd service that checks whether
v4l2loopback.ko exists for the Fedora default boot kernel and whether
the module is signed with the expected Secure Boot signing key.

The kernel module itself is not shipped by this RPM. It is compiled
locally for the Fedora default boot kernel by the management utility.

%prep
%autosetup -n v4l2loopback-%{version}

%build
# Nothing to build.
# This RPM packages the v4l2loopback management shell script.

%install
install -Dpm0755 v4l2loopback.sh \
    %{buildroot}%{_bindir}/v4l2loopback

%preun
# $1 == 0 means final package removal.
# Do not show this message during an RPM upgrade.
if [ "$1" -eq 0 ]; then
    echo
    echo "================================================================"
    echo " WARNING: v4l2loopback-manager is being removed."
    echo
    echo " Recommended cleanup BEFORE removing this package:"
    echo
    echo "   sudo v4l2loopback uninstall"
    echo "   sudo v4l2loopback disable-systemd"
    echo
    echo " The RPM does NOT automatically remove the locally built"
    echo " v4l2loopback kernel module, MOK state, source tree, signing"
    echo " keys, or dynamically-created systemd unit."
    echo
    echo " If those cleanup commands were not run before this DNF"
    echo " transaction, /usr/bin/v4l2loopback will be removed when"
    echo " the transaction completes."
    echo "================================================================"
    echo
fi

# Never fail the RPM transaction because of this informational scriptlet.
:

%files
%license LICENSE

%doc README.md
%doc FAQ.md
%doc TEST.md
%doc CONTRIBUTING.md
%doc SECURITY.md
%doc CHANGELOG.md

%{_bindir}/v4l2loopback

%changelog
* Fri Aug 28 2026 hhlp <louzaoh@gmail.com> - 1.0.3-1
- Added `CHANGELOG.md` to maintain a structured release history following Keep a Changelog conventions.
- Added `CONTRIBUTING.md` with development requirements, contribution workflow, testing guidelines, RPM validation, commit conventions, and security guidance.
- Added `SECURITY.md` documenting supported versions, private vulnerability reporting, MOK private-key handling, privileged operations, and the project security model.
- Added GitHub Issue Forms for bug reports and feature requests.
- Added GitHub issue configuration with dedicated links for private security reports and upstream `v4l2loopback` issues.
- Added a Pull Request template with testing, packaging, documentation, and security checklists.
- Added a GitHub Actions ShellCheck workflow for Bash syntax validation and static analysis.
- Added a GitHub Actions RPM build workflow to validate the SPEC, build SRPM and binary RPM packages, rebuild from the generated SRPM, and inspect the resulting package.
- Added RPM artifact validation for the installed manager path and packaged documentation.
- Added release-preparation tooling for synchronizing release information between `CHANGELOG.md` and `v4l2loopback.spec`.
- Added automatic GitHub Release support based on version tags and `CHANGELOG.md` release entries.
- Added `example.work-flow.md` as a example of a Work-Flow for future use.
- Expanded `README.md` into the main project landing page with installation, architecture, Secure Boot, kernel-selection, rebuild, systemd, verification, removal, and project-scope documentation.
- Added project flow diagrams describing the module build, signing, rebuild, systemd, and responsibility-boundary workflows.
- Improved project documentation navigation with tables of contents and cross-document references.
- Extended ShellCheck coverage to include project maintenance and release scripts.
- Extended RPM CI triggers to include SPEC, changelog, release tooling, and workflow changes.
- Improved RPM CI validation to verify package metadata, expected files, generated SRPMs, binary RPMs, and SRPM rebuildability.
- Standardized release preparation around `CHANGELOG.md` as the primary human-maintained source of release changes.
- Prepared the project for automated GitHub Release and COPR release workflows.

* Thu Aug 27 2026 hhlp <louzaoh@gmail.com> - 1.0.2-1
- Use the Fedora default boot kernel as the module build target
- Detect the target kernel using grubby --default-kernel
- Verify that v4l2loopback.ko is signed with the expected MOK certificate
- Rebuild when the module is missing, unsigned, or signed by another key
- Keep needs-rebuild exit codes compatible with systemd ExecCondition
- Add grubby runtime dependency
- Update systemd service descriptions, documentation, and tests

* Thu Aug 27 2026 hhlp <louzaoh@gmail.com> - 1.0.1-1
- Use /usr/bin/v4l2loopback as the canonical Fedora executable path
- Install the manager with %{_bindir}
- Update generated systemd integration to use /usr/bin/v4l2loopback

* Thu Aug 27 2026 hhlp <louzaoh@gmail.com> - 1.0.0-1
- Initial COPR package
- Install management utility as /usr/bin/v4l2loopback
- Add package-removal cleanup warning
