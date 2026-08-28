#!/usr/bin/env bash

set -Eeuo pipefail

readonly CHANGELOG="CHANGELOG.md"
readonly SPEC="v4l2loopback.spec"

usage() {
    cat <<'EOF'
Usage:
    ./scripts/prepare-release.sh VERSION

Example:
    ./scripts/prepare-release.sh 1.0.3

The script:

    1. Reads the current [Unreleased] section from CHANGELOG.md
    2. Creates the new release section
    3. Updates Version: in v4l2loopback.spec
    4. Generates the RPM %changelog entry
    5. Updates CHANGELOG comparison links
    6. Validates the SPEC with rpmspec

The script does NOT:

    - commit changes
    - create a Git tag
    - push anything
    - create the GitHub Release

Those operations remain explicit so the generated release can be
reviewed before publication.
EOF
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

VERSION="$1"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "Invalid version: $VERSION (expected X.Y.Z)"
fi

[[ -f "$CHANGELOG" ]] || die "$CHANGELOG not found"
[[ -f "$SPEC" ]] || die "$SPEC not found"

CURRENT_VERSION="$(
    awk '
        $1 == "Version:" {
            print $2
            exit
        }
    ' "$SPEC"
)"

[[ -n "$CURRENT_VERSION" ]] ||
    die "Unable to determine current Version from $SPEC"

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
    die "Version $VERSION is already present in $SPEC"
fi

if grep -Fq "## [$VERSION]" "$CHANGELOG"; then
    die "Version $VERSION already exists in $CHANGELOG"
fi

RELEASE_DATE="$(date '+%Y-%m-%d')"
RPM_DATE="$(LC_ALL=C date '+%a %b %d %Y')"

RPM_CHANGELOG_NAME="${RPM_CHANGELOG_NAME:-$(git config user.name || true)}"
RPM_CHANGELOG_EMAIL="${RPM_CHANGELOG_EMAIL:-$(git config user.email || true)}"

[[ -n "$RPM_CHANGELOG_NAME" ]] ||
    RPM_CHANGELOG_NAME="hhlp"

[[ -n "$RPM_CHANGELOG_EMAIL" ]] ||
    RPM_CHANGELOG_EMAIL="hhlp@users.noreply.github.com"

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

UNRELEASED_BODY="$TMP_DIR/unreleased.txt"
RPM_ITEMS="$TMP_DIR/rpm-items.txt"
NEW_CHANGELOG="$TMP_DIR/CHANGELOG.md"
NEW_SPEC="$TMP_DIR/v4l2loopback.spec"

# ------------------------------------------------------------
# Extract [Unreleased]
# ------------------------------------------------------------

awk '
    /^## \[Unreleased\]$/ {
        found = 1
        next
    }

    found && /^## \[[^]]+\]/ {
        exit
    }

    found && /^---$/ {
        next
    }

    found {
        print
    }
' "$CHANGELOG" > "$UNRELEASED_BODY"

if ! grep -qE '^[[:space:]]*[-*+][[:space:]]+' "$UNRELEASED_BODY"; then
    die "CHANGELOG.md [Unreleased] contains no release entries"
fi

# ------------------------------------------------------------
# Convert Markdown release bullets into RPM changelog bullets.
#
# Supported Markdown bullets:
#
# - Entry
# * Entry
# + Entry
#
# Wrapped Markdown lines are joined into a single RPM changelog
# entry.
#
# Example:
#
# * Changed target kernel selection to use Fedora's configured default
#   boot kernel.
#
# becomes:
#
# - Changed target kernel selection to use Fedora's configured default boot kernel.
# ------------------------------------------------------------

awk '
    function flush_item() {
        if (item != "") {
            print "- " item
            item = ""
        }
    }

    /^[[:space:]]*[-*+][[:space:]]+/ {
        flush_item()

        line = $0
        sub(/^[[:space:]]*[-*+][[:space:]]+/, "", line)

        item = line
        next
    }

    item != "" && /^[[:space:]]+/ {
        line = $0
        sub(/^[[:space:]]+/, "", line)

        if (line != "" && line !~ /^```/ && line !~ /^###/) {
            item = item " " line
        }

        next
    }

    {
        flush_item()
    }

    END {
        flush_item()
    }
' "$UNRELEASED_BODY" > "$RPM_ITEMS"

[[ -s "$RPM_ITEMS" ]] ||
    die "Unable to generate RPM changelog entries"

# ------------------------------------------------------------
# Create new CHANGELOG release section.
# ------------------------------------------------------------

awk \
    -v version="$VERSION" \
    -v date="$RELEASE_DATE" '
    /^## \[Unreleased\]$/ {
        print
        print ""
        print "---"
        print ""
        print "## [" version "] - " date
        next
    }

    {
        print
    }
' "$CHANGELOG" > "$NEW_CHANGELOG"

# ------------------------------------------------------------
# Update CHANGELOG comparison links.
#
# Before:
# [Unreleased]: .../compare/v1.0.2...HEAD
#
# After:
# [Unreleased]: .../compare/v1.0.3...HEAD
# [1.0.3]: .../compare/v1.0.2...v1.0.3
# ------------------------------------------------------------

python3 - "$NEW_CHANGELOG" "$VERSION" "$CURRENT_VERSION" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
version = sys.argv[2]
previous = sys.argv[3]

text = path.read_text()

old_unreleased = (
    f"[Unreleased]: "
    f"https://github.com/hhlp/v4l2loopback/compare/"
    f"v{previous}...HEAD"
)

new_links = (
    f"[Unreleased]: "
    f"https://github.com/hhlp/v4l2loopback/compare/"
    f"v{version}...HEAD\n"
    f"[{version}]: "
    f"https://github.com/hhlp/v4l2loopback/compare/"
    f"v{previous}...v{version}"
)

if old_unreleased not in text:
    raise SystemExit(
        "ERROR: Unable to locate the expected [Unreleased] comparison link"
    )

path.write_text(text.replace(old_unreleased, new_links, 1))
PY

# ------------------------------------------------------------
# Update SPEC Version.
# ------------------------------------------------------------

awk \
    -v version="$VERSION" '
    $1 == "Version:" {
        printf "%-15s %s\n", "Version:", version
        next
    }

    {
        print
    }
' "$SPEC" > "$NEW_SPEC"

# ------------------------------------------------------------
# Add RPM %changelog entry.
# ------------------------------------------------------------

RPM_HEADER="* ${RPM_DATE} ${RPM_CHANGELOG_NAME} <${RPM_CHANGELOG_EMAIL}> - ${VERSION}-1"

awk \
    -v header="$RPM_HEADER" \
    -v items="$RPM_ITEMS" '
    {
        print
    }

    $0 == "%changelog" {
        print header

        while ((getline line < items) > 0) {
            print line
        }

        close(items)
        print ""
    }
' "$NEW_SPEC" > "${NEW_SPEC}.with-changelog"

mv "${NEW_SPEC}.with-changelog" "$NEW_SPEC"

# ------------------------------------------------------------
# Validate generated SPEC before touching repository files.
# ------------------------------------------------------------

if command -v rpmspec >/dev/null 2>&1; then
    rpmspec -P "$NEW_SPEC" >/dev/null ||
        die "Generated SPEC failed rpmspec validation"
else
    printf '%s\n' \
        "WARNING: rpmspec is not installed; SPEC validation skipped." >&2
fi

# ------------------------------------------------------------
# Install generated files.
# ------------------------------------------------------------

cp "$NEW_CHANGELOG" "$CHANGELOG"
cp "$NEW_SPEC" "$SPEC"

printf '\n'
printf 'Release preparation complete.\n'
printf '\n'
printf '  Previous version : %s\n' "$CURRENT_VERSION"
printf '  New version      : %s\n' "$VERSION"
printf '  Release date     : %s\n' "$RELEASE_DATE"
printf '\n'

printf 'Updated:\n'
printf '  %s\n' "$CHANGELOG"
printf '  %s\n' "$SPEC"
printf '\n'

printf 'Review the result:\n\n'
printf '  git diff -- %s %s\n' "$CHANGELOG" "$SPEC"
printf '\n'

printf 'If everything is correct:\n\n'
printf '  git add %s %s\n' "$CHANGELOG" "$SPEC"
printf '  git commit -m "chore: prepare v%s release"\n' "$VERSION"
printf '  git tag -a "v%s" -m "v%s"\n' "$VERSION" "$VERSION"
printf '  git push origin main\n'
printf '  git push origin "v%s"\n' "$VERSION"
printf '\n'