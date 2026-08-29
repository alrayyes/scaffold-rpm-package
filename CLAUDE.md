# scaffold-rpm-package

A GitHub template repo, not a distributed package. It's built from
`~/.config/claude/CLAUDE.md` and `~/.config/claude/rules/*.md` — read those
for the "why" behind everything below. This file only says what's specific
to this repo.

## What this is

The GitHub-native sibling of `alrayyes/scaffold-rpm-package` on
git.higherlearning.eu, built independently from the same spec rather than
ported — the two are equivalent, not byte-identical. GitHub-native
throughout: `.github/workflows/` (not `.forgejo/workflows/`),
release-please (not semantic-release), Dependabot (not Renovate).

## Commands

```sh
bun run format:check               # bun run lint:md too
docker run --rm -v "$(pwd):/$(basename "$(pwd)")" -w "/$(basename "$(pwd)")" \
  -e HOME="/$(basename "$(pwd)")/.rpm-home" \
  fedora:41@sha256:f1a3fab47bcb3c3ddf3135d5ee7ba8b7b25f2e809a47440936212a3a50957f3d \
  sh scripts/rpm-build-lint.sh
```

Full list and what each one does: [CONTRIBUTING.md](CONTRIBUTING.md).

## Gotchas

- **Branch protection is on.** Unlike a Forgejo repo under `claude`'s own
  account, `gh` acts as the repo owner here, so `main` genuinely requires a
  pull request — this isn't just discipline the way it is on Forgejo.
- **example.spec's comments escape every `%` as `%%`.** RPM's spec parser
  expands macros even inside `#` comments — a bare directive like
  `%autosetup` written unescaped in prose gets executed right there,
  producing a baffling parse error pointing at the wrong line. Confirmed
  the hard way while building this template; keep escaping in any comment
  you add near a macro invocation.
- **`%global debug_package %{nil}` and `BuildArch: noarch` are there
  because the example is a shell script, not a compiled binary.** A project
  stamped from this template that ships a real compiled binary should drop
  both — rpmlint's `no-binary` check exists precisely to catch an
  architecture-specific package with nothing architecture-specific in it.
- **`License: FIXME` is deliberate**, mirroring `LICENSE` being
  deliberately unpicked. rpmlint's `invalid-license` warning on it is
  expected, not a bug to fix in this template.
- **`scripts/rpm-build-lint.sh` fabricates the source tarball from the
  working tree** rather than fetching `Source0`'s real URL — there's no
  tagged release to fetch from until this template is renamed and actually
  used. Same script runs from the pre-push hook, `ci.yml`'s build job, and
  `release-please.yml`'s artefacts job; don't let any of the three drift
  from calling it the same way.
- **The `artefacts` job in `release-please.yml` attaches this template's
  own placeholder RPM to every release this repo cuts** — proof the
  pipeline works, not a real deliverable. A project stamped from this
  template inherits that job and it'll build/attach whatever `example.spec`
  has been renamed to by then.
- **`renovate.json` doesn't exist here.** This repo is GitHub-primary;
  Dependabot (`.github/dependabot.yml`) is what raises dependency pull
  requests.
