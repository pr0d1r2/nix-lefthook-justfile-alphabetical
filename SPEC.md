# SPEC — nix-lefthook-justfile-alphabetical

## §G Goal

Lefthook-compatible justfile recipe-order enforcer. Verify every committed
`justfile` lists its recipes in `LC_ALL=C` alphabetical order. Packaged as a
Nix flake (`writeShellApplication`). Opensource-safe: zero credentials, zero
local paths, zero private refs.

## §C Constraints

- C1: Pure bash + awk — no Python/Ruby/etc runtime deps
- C2: Nix flake — `writeShellApplication` pkg, inline `mkShell` devShells
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`,
  `aarch64-linux`
- C5: Detached — no credential leaks, no hardcoded local paths, no private refs
- C6: Config via `LEFTHOOK_JUSTFILE_ALPHABETICAL_TIMEOUT` only; no config files
  beyond baseline
- C7: Exit non-zero on order violations — hard enforcement, blocks commit
- C8: Flattened inputs — `flake = false` `-src` leaves + `nixpkgs-lock` follows,
  wrappers built inline (no `nix-dev-shell-agentic`)

## §I Interfaces

- I.cli: `lefthook-justfile-alphabetical FILE...` — filters args to `justfile` /
  `*/justfile`, exit 1 on out-of-order recipes, exit 0 on pass / none / no args
- I.env: `LEFTHOOK_JUSTFILE_ALPHABETICAL_TIMEOUT` (seconds, default `30`) —
  wraps the hook in `timeout`
- I.awk: `justfile-alphabetical.awk` — emits recipe names in file order; path
  injected via `AWK_PROGRAM` set by flake.nix
- I.remote: `lefthook-remote.yml` — consumers add as lefthook remote
  (pre-commit + pre-push, `glob: "justfile"`)
- I.flake: `packages.${system}.default` — Nix pkg output
- I.devshell: `devShells.${system}.default` + `.#ci` — inline `mkShell`,
  identical package set; `default` runs `dev.sh` shellHook, `ci` sets
  `BATS_LIB_PATH`
- I.ci: `ci.yml` — linux + macos via `nix-lefthook-ci-action`; `update-pins.yml`
  — scheduled `nixpkgs-lock` pin-bump PR

## §V Invariants

- V1: Recipe names in file order must equal their `LC_ALL=C` sort — else exit 1
  with the first offending pair
- V2: Only `justfile` / `*/justfile` paths are checked; other args skipped
- V3: Missing files skipped silently (no crash)
- V4: No args, no matching justfiles, or empty justfile → exit 0
- V5: Comment lines (`^[[:space:]]*#`) ignored by the awk extractor
- V6: `[private]` recipes excluded — the line after `[private]` is skipped
- V7: The `default` recipe excluded from the ordering check
- V8: Recipe detection matches `^[a-z][a-zA-Z0-9_-]*` plus optional param words,
  up to the first `:`
- V9: Exits 1 when recipes are out of order — hard requirement, blocks commit
- V10: `LEFTHOOK_JUSTFILE_ALPHABETICAL_TIMEOUT` bounds run time; default `30`s
- V11: No credentials, secrets, tokens, keys, or private paths in tracked files
- V12: No hardcoded local paths (enforced by `git-no-local-paths` hook)
- V13: `dev.sh` sets `BATS_LIB_PATH` and installs lefthook when
  `.git/hooks/pre-commit` is missing
- V14: CI runs both pre-commit and pre-push on linux + macos
- V15: All linters pass: shellcheck, shfmt, nixfmt, statix, deadnix, yamllint,
  typos, editorconfig-checker, bats-parse, bats-unit, file-size-check,
  nix-no-embedded-shell, trailing-whitespace, missing-final-newline,
  git-conflict-markers, git-no-local-paths, nix-flake-check
- V16: Flattened flake — no `nix-dev-shell-agentic`; each lint wrapper built
  inline from its `flake = false` `-src` input; `flake.lock` minimal
- V17: `file_size_limits.yml` raises `nix: 10240` for the inline-wrapper flake
  and `md: 8192` for this spec

## §T Tasks

| id | status | task | cites |
| --- | --- | --- | --- |
| T1 | x | core enforcer: filter justfiles, awk-extract, assert sorted, exit 1 on gap | V1,V2,V3,V4,V9,I.cli |
| T2 | x | awk extractor: skip comments, `[private]`, `default`; emit names in order | V5,V6,V7,V8,I.awk |
| T3 | x | inject `AWK_PROGRAM` nix-store path via flake.nix | C1,I.awk,I.flake |
| T4 | x | env config: timeout (default 30) | V10,I.env,C6 |
| T5 | x | Nix flake pkg (`writeShellApplication`, gawk + coreutils) | C1,C2,I.flake |
| T6 | x | inline `mkShell` devShells (`default` + `ci`), no agentic input | C2,C8,I.devshell,V16 |
| T7 | x | inline lefthook wrappers, one per `flake = false` `-src` input | C8,V15,V16 |
| T8 | x | lefthook-remote.yml + lefthook.yml (pre-commit + pre-push) | I.remote,I.ci |
| T9 | x | dev.sh — BATS_LIB_PATH + auto-install lefthook | V13 |
| T10 | x | unit tests: lefthook-justfile-alphabetical.bats | V1-V9 |
| T11 | x | unit tests: dev.bats (3 tests) | V13 |
| T12 | x | CI: linux + macos via nix-lefthook-ci-action | V14,I.ci |
| T13 | x | scheduled update-pins workflow for nixpkgs-lock | I.ci |
| T14 | x | linter suite via lefthook remotes | V15 |
| T15 | x | opensource audit: no credentials/local-paths/private-refs in history | V11,V12,C5 |
| T16 | x | .gitignore: `.claude/`, `.env`, sensitive patterns | V11,C5 |
| T17 | x | flatten flake: drop agentic, inline wrappers, raise nix file-size limit | C8,V16,V17 |
