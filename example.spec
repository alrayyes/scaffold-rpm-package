# example.spec — rename this file (and every Name/%%{name} below) to your
# project's own name before you package anything real with it.
#
# No compiled binary ships in this package (the example is a shell script),
# so there is nothing for find-debuginfo to extract — without this line,
# rpmbuild fails on an empty debugsourcefiles.list. Drop it the day the
# project being packaged builds a real binary.
%global debug_package %{nil}

Name:           example
Version:        1.0.0
Release:        1%{?dist}
Summary:        Placeholder package produced by the scaffold-rpm-package template
# Pick a real SPDX identifier once the project has one — see LICENSE at the
# repo root, which is deliberately unpicked. rpmlint flags this placeholder
# (invalid-license); that's expected until it's replaced.
License:        FIXME
URL:            https://github.com/alrayyes/scaffold-rpm-package
# GitHub's tag-archive endpoint. The `#/%%{name}-%%{version}.tar.gz` fragment
# is what rpmbuild saves the download as locally — without it the local
# filename would be the URL's own basename (v%%{version}.tar.gz), which
# %%autosetup below doesn't expect.
#
# NOTE: macros are expanded even inside spec-file comments, and a bare
# directive like %%autosetup (unlike a bracketed %%{name}) would otherwise
# execute right here — hence the %% escaping throughout this file's prose.
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
# The example installs a shell script, not a compiled binary, so it runs
# unchanged on every architecture. Drop this the day the packaged project
# ships an actual compiled binary — rpmlint's no-binary check exists to
# catch an architecture-specific package with nothing arch-specific in it,
# which is exactly what BuildArch: noarch fixes.
BuildArch:      noarch

BuildRequires:  make

%description
Placeholder package produced by scaffold-rpm-package, a template for
packaging a project as an RPM. Replace this description, and everything
else in this spec, with your own project's.

%prep
# GitHub names the extracted directory after the *repository*
# (scaffold-rpm-package), not after this spec's package Name (example) —
# those two are allowed to differ, and normally will once this is renamed.
# -n tells %%autosetup which directory actually landed on disk.
%autosetup -n scaffold-rpm-package-%{version}

%build
%make_build

%install
%make_install PREFIX=/usr

%check
# A real project runs its actual test suite here. This is a smoke test
# proving the installed-from script at least executes.
sh bin/example-tool

%files
%{_bindir}/example-tool

%changelog
* Sat Aug 29 2026 Ryan Kes <ryan@andthensome.nl> - 1.0.0-1
- Initial packaging.
