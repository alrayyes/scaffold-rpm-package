# scaffold-rpm-package

[![CI](https://github.com/alrayyes/scaffold-rpm-package/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/alrayyes/scaffold-rpm-package/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/alrayyes/scaffold-rpm-package?sort=semver)](https://github.com/alrayyes/scaffold-rpm-package/releases/latest)
[![licence](https://img.shields.io/badge/licence-unlicensed-lightgrey)](LICENSE)

A GitHub template for packaging a project as an RPM. Run `gh repo create
my-real-project --template alrayyes/scaffold-rpm-package` and you get a
spec file, a build+lint pipeline that actually runs, prose linting, secret
scanning, and release automation already wired in — rather than a blank
directory and a packaging guide to work through by hand.

It isn't a real package on its own. `example.spec` packages a placeholder
shell script (`bin/example-tool`) so the whole chain — spec, build,
install, `%check`, lint, CI, release — has something real to run against.
Replace the source tree and the spec with your own project's and delete
this paragraph.

## Requirements

- **[Docker](https://docs.docker.com/get-docker/)**, for building and
  linting the spec inside a pinned Fedora container — see
  [CONTRIBUTING.md](CONTRIBUTING.md) for why it's containerized rather
  than run against whatever RPM tooling (if any) is on your own machine.
- **[bun](https://bun.sh)**, for the tooling that isn't RPM packaging —
  commitlint, Prettier, markdownlint, and the
  [lefthook](https://lefthook.dev) that runs the git hooks.

## Adapting this template

1. Rename `example.spec` to `<your-project>.spec` and update every field
   in it — `Name`, `Version`, `Release`, `Summary`, `License` (currently
   the placeholder `FIXME`; rpmlint flags it deliberately until you pick a
   real SPDX identifier matching whatever you put in `LICENSE`), `URL`, and
   `Source0`. `%description` and `%changelog` are yours to rewrite too.
2. Replace `Makefile` and `bin/example-tool` with your real project's
   source tree and real build system — anything `%build`/`%install` can
   drive is fine, it doesn't have to be `make`.
3. Drop `%global debug_package %{nil}` and `BuildArch: noarch` from the
   spec once you're packaging a real compiled binary — both exist only
   because the placeholder is a shell script. See the comments beside each
   in `example.spec`.
4. Update `%files` to list what your `%install` actually installs.

`Source0` points at GitHub's tag-archive endpoint
(`%{url}/archive/refs/tags/v%{version}.tar.gz`) — the real download this
package builds from once you've tagged a release. Until then,
`scripts/rpm-build-lint.sh` fabricates an equivalent tarball from the
current working tree so the spec can be built and linted locally and in CI
without a tag existing yet.

## Building and linting locally

```sh
docker run --rm -v "$(pwd):/$(basename "$(pwd)")" -w "/$(basename "$(pwd)")" \
  -e HOME="/$(basename "$(pwd)")/.rpm-home" \
  fedora:41@sha256:f1a3fab47bcb3c3ddf3135d5ee7ba8b7b25f2e809a47440936212a3a50957f3d \
  sh scripts/rpm-build-lint.sh
```

This is the same command the pre-push hook and `ci.yml`'s build job run.
It installs `rpmdevtools`/`rpmlint`/`make` inside the container, stages the
working tree as `rpmbuild -ba` expects, builds the RPM and SRPM, and runs
`rpmlint` against the spec and every built package. Built packages land
under `.rpm-home/rpmbuild/` (gitignored).

It then `dnf install`s the built RPM for real, checks that every file it
lists as installed is actually present on disk, and runs the installed
`example-tool` to confirm it executes and prints what it should — build
and lint clean only prove the spec is well-formed, not that installing it
leaves a working package behind.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the toolchain, the hooks, and
how a change gets reviewed and released.

## Publishing an RPM

Building an RPM locally is one thing; getting it somewhere other people
can `dnf install` it from is another. Three real options, roughly ordered
by barrier to entry:

### Fedora COPR — lowest barrier

[COPR](https://copr.fedorainfracloud.org/) is Fedora's personal package
repository service: low-barrier, no review process to publish. Sign in
with a Fedora Account System (FAS) account, create a project (web UI or
`copr-cli`), generate an API token from the web UI and place it in
`~/.config/copr`, then:

```sh
copr-cli build <your-project> path/to/your.src.rpm
```

builds it against whichever chroots the project targets (`fedora-*`,
`epel-*`, and others). Consumers add your repo with
`dnf copr enable <you>/<your-project>` and install normally. Docs:
<https://docs.copr.fedorainfracloud.org/>.

### openSUSE Open Build Service — also low-barrier

[OBS](https://build.opensuse.org/) is openSUSE's build service, but it
isn't openSUSE-only — it builds packages for openSUSE, Fedora, CentOS/RHEL,
Debian, Ubuntu and more from one source. Free signup gets you a personal
"home project" (`home:<username>`) immediately, with no review gate to
start publishing — genuinely lower-barrier than Fedora's own process,
despite being a different distro's infrastructure.

### The Fedora Package Review Process — highest barrier, most official

Getting a package into Fedora proper (and from there, into RHEL/CentOS's
orbit) is the most official route and the highest barrier:

1. File a Bugzilla request in the "Package Review" component — the
   summary has to start with "Package Review Request:" or `fedpkg
request-repo` rejects it later.
2. The spec and SRPM get reviewed against the
   [Fedora Packaging Guidelines](https://fedoraproject.org/wiki/Packaging:ReviewGuidelines)
   by an existing sponsored packager. If you aren't one yourself yet, your
   review request also needs a sponsor (flagged `FE-NEEDSPONSOR`) to get
   you into the `packager` group.
3. Once approved: `fedpkg request-repo` and `fedpkg import` get you a
   dist-git repo, `fedpkg build` builds it in Koji, and
   [Bodhi](https://bodhi.fedoraproject.org/) handles the karma/stable-push
   process for updates.

Start here: [Joining the Package
Maintainers](https://docs.fedoraproject.org/en-US/package-maintainers/Joining_the_Package_Maintainers/).

## Licence

No licence has been chosen yet — see [`LICENSE`](LICENSE). Pick one before
a project stamped from this template goes anywhere public, and set a real
`License:` value in its spec file to match.
