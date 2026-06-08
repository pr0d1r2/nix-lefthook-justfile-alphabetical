# SPEC — flatten nix-lefthook-justfile-alphabetical

## Goal
Drop the `nix-dev-shell-agentic` flake input (which drags ~30x duplicated
dependency tree into consumers) and rebuild the dev shells inline, mirroring
the proven `nix-lefthook-statix` / `nix-lefthook-nix-no-embedded-shell`
templates. No behavioral change to any produced output.

## Preserved verbatim
- `packages.default` = `lefthook-justfile-alphabetical`:
  - `runtimeInputs = [ pkgs.gawk pkgs.coreutils ]`
  - text = `AWK_PROGRAM="${./justfile-alphabetical.awk}"\n` + readFile
    `./lefthook-justfile-alphabetical.sh`
- `dev.sh` (BATS_LIB_PATH + lefthook install) unchanged.
- `lefthook.yml`, hook logic, awk program, tests: unchanged.

## Input changes
REMOVE:
- `nix-dev-shell-agentic`

KEEP:
- `nixpkgs-lock.url = github:pr0d1r2/nixpkgs-lock`
- `nixpkgs.follows = nixpkgs-lock/nixpkgs`

ADD (all `flake = false` source leaves — one per remote that needs a wrapper
binary; siblings-in-remotes rule):
- nix-lefthook-bats-parse-src
- nix-lefthook-bats-unit-src
- nix-lefthook-deadnix-src
- nix-lefthook-editorconfig-checker-src
- nix-lefthook-file-size-check-src
- nix-lefthook-git-conflict-markers-src
- nix-lefthook-git-no-local-paths-src
- nix-lefthook-missing-final-newline-src
- nix-lefthook-nix-no-embedded-shell-src
- nix-lefthook-nixfmt-src
- nix-lefthook-shellcheck-src
- nix-lefthook-shfmt-src
- nix-lefthook-statix-src
- nix-lefthook-trailing-whitespace-src
- nix-lefthook-typos-src
- nix-lefthook-yamllint-src

(`nix-flake-check` remote needs only `pkgs.nix`; `bats-parse` needs `pkgs.bats`
— no extra wrapper binary beyond what the shell already supplies.)

## devShells (inline, replacing nix-dev-shell-agentic.lib.mkShells)
`default` = `ci` = `pkgs.mkShell` with:
- self.packages.default (lefthook-justfile-alphabetical)
- batsWithLibs (bats.withLibraries: bats-support, bats-assert, bats-file)
- pkgs.coreutils, pkgs.git, pkgs.lefthook, pkgs.nix, pkgs.parallel
- all lefthook wrappers (built via `wrap` helper reading `${src}/${name}.sh`)
- BATS_LIB_PATH set in ci; dev.sh shellHook in default (placeholder replaced)
The `lefthook-nix-no-embedded-shell` wrapper sets `SCANNER` prefix to the
src's `scan-nix-no-embedded-shell.sh` (mirrors that repo's own flake).

## Anti-bloat
Only flake.nix grows (+ inline wrappers, a few hundred lines). Bump
`config/lefthook/file_size_limits.yml` `nix: 4096 → 10240` (mirrors statix).
No external files vendored. shfmt -i2 -ci formatting on flake.nix if needed.

## Gate
1. `nix flake check` green.
2. `nix flake show` lists same outputs (packages.default + devShells).
3. `lefthook run pre-commit --all-files` passes inside `nix develop`.
4. flake.lock node count drops substantially (59 → ~18 expected).
Only then: branch flatten-drop-agentic, commit, push, draft PR.
