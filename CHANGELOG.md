# Changelog

All notable changes to this project are documented here.

## Unreleased

### Fixed

- Restore the `lefthook-justfile-alphabetical` package (`packages.default`)
  and its build check, dropped by the vendored-to-referenced migration.
- Put the packaged wrapper on every devShell PATH so the unit tests run.
- Load bats libraries with `bats_load_library` and stop clobbering `TMPDIR`
  in `dev.bats`.
- Bump the set-and-setting pin so CI, which runs the current standard,
  finds the bats libraries; drop the actionlint overrides the new standard
  no longer needs.
