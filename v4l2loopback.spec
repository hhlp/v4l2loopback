Name:           v4l2loopback-manager
Version:        1.0.0
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

%description
v4l2loopback-manager is a Fedora management utility for building,
signing, installing, rebuilding, and removing the v4l2loopback
kernel module.

It supports Secure Boot using a Machine Owner Key (MOK) and can
optionally create and enable a systemd service that checks whether
v4l2loopback.ko exists for the newest installed Fedora kernel-devel.

The kernel module itself is not shipped by this RPM. It is compiled
locally for the newest installed kernel-devel by the management
utility.

%prep
%autosetup -n v4l2loopback-%{version}

%build
# Nothing to build.
# This RPM packages the v4l2loopback management shell script.

%install
install -Dpm0755 v4l2loopback.sh \
    %{buildroot}%{_sbindir}/v4l2loopback

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
    echo " transaction, /usr/sbin/v4l2loopback will be removed when"
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
%{_sbindir}/v4l2loopback

%changelog
* Thu Aug 27 2026 hhlp <hhlp@users.noreply.github.com> - 1.0.0-1
- Initial COPR package
- Install management utility as /usr/sbin/v4l2loopback
- Add package-removal cleanup warning
