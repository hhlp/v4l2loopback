# Pull Request

Thank you for contributing to `v4l2loopback-manager`.

Please provide enough information for the change to be reviewed and tested safely.

---

## Table of Contents

- [Summary](#summary)
- [Related Issue](#related-issue)
- [Type of Change](#type-of-change)
- [Affected Areas](#affected-areas)
- [Testing](#testing)
- [RPM and Packaging](#rpm-and-packaging)
- [Documentation](#documentation)
- [Security](#security)
- [Final Checklist](#final-checklist)

---

## Summary

Describe what this Pull Request changes and why.

<!--
Explain the purpose of the change.

Keep the description focused on the behavior changed by this PR.
-->

---

## Related Issue

<!--
Examples:

Fixes #123
Closes #123
Related to #123

Use "N/A" when there is no related issue.
-->

Related issue:

---

## Type of Change

Select all that apply:

- [ ] Bug fix
- [ ] New feature
- [ ] Hotfix
- [ ] Refactoring
- [ ] Documentation
- [ ] Tests
- [ ] RPM / packaging
- [ ] CI / GitHub Actions
- [ ] Security-related change
- [ ] Other

---

## Affected Areas

Select all areas affected by this PR:

- [ ] Manager CLI
- [ ] Kernel selection
- [ ] Module compilation
- [ ] Secure Boot / MOK
- [ ] Module signing
- [ ] Signature verification
- [ ] `needs-rebuild`
- [ ] systemd integration
- [ ] Module configuration
- [ ] Installation
- [ ] Uninstallation
- [ ] RPM SPEC
- [ ] COPR packaging
- [ ] Documentation
- [ ] Tests
- [ ] GitHub configuration
- [ ] CI
- [ ] Other

---

## Testing

Describe how the change was tested.

<!--
Include relevant commands and results.

For changes to v4l2loopback.sh, typical checks include:

bash -n v4l2loopback.sh
shellcheck v4l2loopback.sh

Follow TEST.md when the change affects manager behavior.
-->

### Static checks

- [ ] `bash -n v4l2loopback.sh` passes, or the shell script was not modified.
- [ ] `shellcheck v4l2loopback.sh` passes, or the shell script was not modified.

### Functional tests

- [ ] Relevant tests from `TEST.md` were performed.
- [ ] Not applicable.

### Test environment

Fedora version:

```text

```

Running kernel:

```text

```

Fedora default boot kernel:

```text

```

Secure Boot:

```text
Enabled / Disabled / Not applicable
```

### Test results

```text
Describe or paste the relevant results here.
```

---

## RPM and Packaging

Complete this section when the change affects RPM packaging.

- [ ] `v4l2loopback.spec` was not affected.
- [ ] `rpmspec -P v4l2loopback.spec` succeeds.
- [ ] Package metadata was reviewed.
- [ ] RPM/COPR behavior was tested where appropriate.
- [ ] Runtime dependencies were reviewed.
- [ ] `%files` was reviewed for newly added or removed packaged files.
- [ ] `%changelog` was updated if required.

Additional packaging notes:

```text
N/A
```

---

## Documentation

Select all that apply:

- [ ] No documentation changes are required.
- [ ] `README.md` was updated.
- [ ] `FAQ.md` was updated.
- [ ] `TEST.md` was updated.
- [ ] `CONTRIBUTING.md` was updated.
- [ ] `SECURITY.md` was updated.
- [ ] `CHANGELOG.md` was updated.
- [ ] Other documentation was updated.

User-visible behavior changes should normally be reflected in the appropriate documentation.

---

## Security

This project performs privileged operations involving kernel modules and Secure Boot signing.

Confirm that this PR does **not** expose:

- MOK private keys.
- Passwords.
- Authentication tokens.
- API keys.
- SSH private keys.
- Credentials.
- Other secrets.

The following file must never be committed or attached:

```text
/var/lib/shim-signed/mok/v4l.key
```

Security-sensitive changes should also be reviewed against `SECURITY.md`.

---

## Final Checklist

Before requesting review:

- [ ] My branch is based on the current `main`.
- [ ] The change has a clear and focused purpose.
- [ ] I reviewed my own diff.
- [ ] I did not include unrelated changes.
- [ ] I did not commit generated RPMs or build artifacts.
- [ ] I did not commit private keys, credentials, or secrets.
- [ ] Relevant tests pass.
- [ ] Documentation was updated when necessary.
- [ ] `CHANGELOG.md` was updated for user-visible changes.
- [ ] The change remains within the scope of `v4l2loopback-manager`.

---

## Additional Notes

Add anything else reviewers should know.

```text
N/A
```