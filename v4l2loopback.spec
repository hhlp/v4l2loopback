Name:           v4l2loopback-manager
Version:        1.0.6
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
# Interactive cleanup is intentionally not performed from RPM scriptlets.
# The recommended complete-removal path is `v4l2loopback purge`, which
# performs cleanup before asking DNF to remove this package.
if [ "$1" -eq 0 ]; then
    if [ -e /etc/systemd/system/v4l2loopback-rebuild.service ] ||
       [ -e /var/lib/shim-signed/mok/v4l.key ] ||
       [ -e /var/lib/shim-signed/mok/v4l.der ]; then

        echo
        echo "v4l2loopback-manager integration may still be configured."
        echo
        echo "For complete cleanup before RPM removal, cancel this transaction"
        echo "and run:"
        echo
        echo "    sudo v4l2loopback purge"
        echo
        echo "The purge command processes vmwmanager integration resources"
        echo "and then starts the DNF removal transaction itself."
        echo
    fi
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
* Fri Sep 11 2026 hhlp <2659606+hhlp@users.noreply.github.com> - 1.0.6-1
- add to .spec only show the message is leftlover exist

* Sun Sep 06 2026 hhlp <2659606+hhlp@users.noreply.github.com> - 1.0.5-1
- Added the `purge` command for complete removal of resources managed by `v4l2loopback-manager` followed by removal of the manager RPM through DNF.
- Added explicit tracking of pending MOK certificate deletion during `uninstall` and `purge`.
- Added final purge status reporting to distinguish a fully completed removal from one that still requires manual MOK deletion confirmation after reboot.
- `uninstall` now also disables and removes the dynamically-created systemd integration before removing locally managed v4l2loopback resources.
- `uninstall` continues to keep the `v4l2loopback-manager` RPM installed, while `purge` performs resource cleanup and then removes the RPM.
- `reinstall` preserves the existing systemd integration while reusing the uninstall cleanup logic, avoiding unintended service removal during a reinstall operation.
- `purge` uses DNF without automatic confirmation so the user retains control over the final RPM removal transaction.
- MOK deletion remains explicitly asynchronous: when certificate deletion is staged with `mokutil`, the manager reports that a manual reboot and confirmation in the blue MOK Manager screen are still required.
- RPM removal no longer attempts or recommends interactive cleanup from the `%preun` scriptlet; interactive resource cleanup is handled by the manager commands instead.
- Direct `dnf remove v4l2loopback-manager` removes only the RPM-managed manager files and intentionally preserves locally-created resources.
- Fixed the package-removal workflow where `%preun` recommended running `v4l2loopback uninstall` after the DNF removal transaction had already started and `/usr/bin/v4l2loopback` was about to be removed.
- Fixed systemd integration being left behind when explicitly uninstalling resources managed by `v4l2loopback-manager`.
- Prevented `reinstall` from unintentionally disabling an existing v4l2loopback systemd integration.
- Prevented `purge` from reporting complete removal when MOK certificate deletion is still pending confirmation during the next reboot.
- MOK certificate deletion continues to require explicit user confirmation and is never completed automatically by the RPM removal process.
- Reboot after staging MOK certificate deletion remains explicitly manual.

* Mon Aug 31 2026 hhlp <2659606+hhlp@users.noreply.github.com> - 1.0.4-1
- Added the `status` command to report the Fedora default boot kernel, Secure Boot state, signing-key files, MOK enrollment, target-module presence, module signer, and running-kernel module state.
- Added explicit MOK enrollment verification before deciding whether a valid signed module requires attention.
- Added recovery guidance for BIOS/UEFI or firmware changes that can leave the existing signing certificate unenrolled.
- `genkey` now preserves an existing complete signing key pair and reuses the existing DER certificate when MOK enrollment must be restored.
- MOK enrollment detection now handles Fedora/mokutil combinations where `mokutil --test-key` can print `is already enrolled` while still returning exit status `1`.
- `needs-rebuild` now distinguishes module validity from MOK trust: a module that already exists and has the expected signer is not rebuilt merely because its MOK enrollment is missing.
- `rebuild` now avoids unnecessary compilation when the module is already correctly signed and instead directs the user to re-enroll the existing certificate when needed.
- MOK recovery instructions now make the reboot step explicitly manual.
- Fixed false `Signing certificate is NOT enrolled` reports caused by relying only on the exit status of `mokutil --test-key`.
- Avoided regenerating signing keys as a response to lost MOK enrollment.
- Added `purge` for complete managed-resource cleanup followed by removal of the v4l2loopback-manager RPM through DNF.
- `uninstall` now disables and removes the dynamically-created systemd integration while keeping the manager RPM installed.
- `reinstall` preserves existing systemd integration while reusing the uninstall cleanup path.
- Track successful MOK deletion requests and clearly report when final removal is pending manual confirmation in the blue MOK Manager screen.
- Never reboot automatically after MOK enrollment or deletion requests.
- Direct RPM removal remains non-interactive and does not automatically remove locally-created modules, MOK state, sources, signing keys, configuration, or dynamically-created systemd resources.

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
