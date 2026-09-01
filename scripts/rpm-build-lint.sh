#!/bin/sh
# Builds and lints the spec against the current working tree, standing in
# for a real tagged-release tarball this template has no tag to fetch yet
# (Source0 in the spec points at one, but nothing downloads it here — see
# the comment there). The same script runs from the pre-push hook (inside
# a `docker run` against the pinned image, since lefthook runs on the bare
# host) and from ci.yml (natively, since that job's container already is
# the pinned image) — one script, so the two paths can't drift on what
# "the build" means.
#
# Expects to run as root (or any user) inside a Fedora/Rocky container with
# dnf on PATH, at the repository root.
set -eu

spec=$(ls ./*.spec | head -1)
name=$(sed -n 's/^Name:[[:space:]]*//p' "$spec" | head -1)
version=$(sed -n 's/^Version:[[:space:]]*//p' "$spec" | head -1)
repo=$(basename "$(pwd)")

command -v rpmbuild >/dev/null 2>&1 || dnf install -y -q rpmdevtools rpmlint make

mkdir -p "$HOME"
rpmdev-setuptree

# A staging directory named "<repo>-<version>" mirrors the directory name
# GitHub's tag-archive endpoint would produce, matching what %prep's
# %autosetup -n expects — see example.spec's %prep comment for why that
# name is the repo's, not the package's.
#
# .rpm-home is excluded too: it's where $HOME points when the caller wants
# this script's own output (and dnf/rpm's incidental .config, .rpmmacros)
# kept out of the actual working tree - packaging it into the source
# tarball would be circular.
staging=$(mktemp -d)
mkdir -p "$staging/${repo}-${version}"
find . -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name node_modules ! -name .rpm-home \
  ! -name '*.rpm' ! -name '*.src.rpm' \
  -exec cp -r {} "$staging/${repo}-${version}/" \;
tar czf "$HOME/rpmbuild/SOURCES/${name}-${version}.tar.gz" \
  -C "$staging" "${repo}-${version}"
rm -rf "$staging"

cp "$spec" "$HOME/rpmbuild/SPECS/"

rpmbuild -ba "$HOME/rpmbuild/SPECS/$(basename "$spec")"

rpmlint "$HOME/rpmbuild/SPECS/$(basename "$spec")"
find "$HOME/rpmbuild/RPMS" -name '*.rpm' -exec rpmlint {} +

# Building and linting only prove the spec is well-formed and rpmbuild
# didn't choke - neither one ever installs the result, so a wrong %files
# entry, or a binary that's non-executable once installed, still passes
# both. Install the just-built package for real and prove it leaves
# working files behind, the same way a person's own `dnf install` would.
find "$HOME/rpmbuild/RPMS" -name '*.rpm' -exec dnf install -y {} +

# rpm's own installed-file list, not the spec's %files section re-parsed
# by hand - this is what actually landed on disk if dnf/rpm's own report
# of success can't be trusted. See rules/packaging.md's "Testing an
# installed package in CI": a slim/minimal base image can silently drop
# files during install while the package manager still calls it a
# success, and `rpm -ql`/dpkg -L would still list them as installed. A
# missing entry here fails the build instead of shipping a package that
# lies about its own contents.
for installed_file in $(rpm -ql "$name"); do
  [ -e "$installed_file" ] || {
    echo "rpm-build-lint: $installed_file is in $name's installed file list but missing on disk" >&2
    exit 1
  }
done

# Prove the installed binary actually runs, not just that a file with its
# name exists on disk - a non-executable or corrupt install still passes
# the existence check above. Update the binary name and expected output
# here when adapting this template to a real project's own entry point.
actual_output=$(example-tool) || {
  echo "rpm-build-lint: installed example-tool did not run successfully" >&2
  exit 1
}
expected_output="Hello from example-tool"
if [ "$actual_output" != "$expected_output" ]; then
  echo "rpm-build-lint: installed example-tool printed '$actual_output', expected '$expected_output'" >&2
  exit 1
fi
