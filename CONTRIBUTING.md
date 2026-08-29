# Contributing

This file is for whoever changes this template. The
[README](README.md) is for whoever stamps a project out of it.

## Getting set up

- **[Docker](https://docs.docker.com/get-docker/)**, on your `PATH`. The
  spec builds and lints inside a pinned Fedora container rather than
  against whatever `rpmbuild`/`rpmlint` a contributor's own machine
  happens to have — RPM tooling is distro-specific and this account's own
  desktop isn't Fedora-based, so there's no "install it locally" path that
  would work the same way for everyone. `scripts/rpm-build-lint.sh` is
  what actually runs; both the pre-push hook and `ci.yml` call it.
- **[bun](https://bun.sh)**, for the tooling that isn't RPM — commitlint,
  Prettier, markdownlint, and the [lefthook](https://lefthook.dev) that
  runs the git hooks. There's a `package.json`, but nothing here is
  JavaScript; it exists only so those tools resolve and stay pinned.

One command installs the linters and the git hooks:

```sh
bun install
```

An uninstalled hook silently does nothing, which is worse than not having
one, so the `prepare` script runs `lefthook install` for you. You find out
at the pipeline otherwise, not at the commit.

## Everyday commands

Every one of these is what a hook or CI runs — see `lefthook.yml` and
`.github/workflows/*.yml` for exactly which.

```sh
bun run format:check       # prettier --check, add --write to fix
bun run lint:md

# Build and lint the RPM, same as the pre-push hook and ci.yml's build job.
# HOME points at .rpm-home/ inside the mounted workspace - `docker run
# --rm` throws away everything else in the container when it exits, and
# rpmbuild/dnf drop more than just the built RPMs under $HOME (.config,
# .rpmmacros), none of which belongs loose in the working tree.
docker run --rm -v "$(pwd):/$(basename "$(pwd)")" -w "/$(basename "$(pwd)")" \
  -e HOME="/$(basename "$(pwd)")/.rpm-home" \
  fedora:41@sha256:f1a3fab47bcb3c3ddf3135d5ee7ba8b7b25f2e809a47440936212a3a50957f3d \
  sh scripts/rpm-build-lint.sh
```

## How it fits together

`example.spec` is the package definition; `Makefile` and `bin/` are the
minimal project it packages, standing in for whatever the real project
being packaged actually builds. `scripts/rpm-build-lint.sh` stages the
current working tree into a synthetic `<repo>-<version>` source tarball —
standing in for the real tagged-release tarball `Source0` names, which
doesn't exist until this template has been used to cut an actual release —
then runs `rpmbuild -ba` and `rpmlint` against it inside the pinned image.
One script, so the hook and CI can't check different things.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): description`, types `feat`/`fix`/`docs`/`style`/`refactor`/
`perf`/`test`/`build`/`ci`/`chore`/`revert`. Subject under 50 characters,
lowercase, no trailing full stop. commitlint enforces the shape at
commit-msg and again in CI; the length and case rules are tighter than
what it checks, so hold to them anyway.

## Branching, review, and release

Every change goes through a pull request — nothing is pushed straight to
`main`, including the bootstrapping that built this repo. Branch
protection on `main` requires a pull request before merging, so this is
also enforced mechanically, not just by discipline.

The pull request **title** has to be a valid Conventional Commit too —
`pr-title.yml` checks it. commitlint only ever reads commit objects, and a
squash merge defaults its commit message to the pull request title, so this
is the only check standing between a badly titled pull request and a bad
message on `main`.

Once a pull request's checks are green, squash-merge it and delete the
branch. [release-please](https://github.com/googleapis/release-please)
reads the Conventional Commits on `main` and keeps a release pull request
open with the next version and changelog entry; merging that one tags the
release. Nobody picks a version by hand.
