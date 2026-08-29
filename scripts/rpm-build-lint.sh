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
