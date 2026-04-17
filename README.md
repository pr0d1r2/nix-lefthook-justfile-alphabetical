# nix-lefthook-justfile-alphabetical

[![CI](https://github.com/pr0d1r2/nix-lefthook-justfile-alphabetical/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-justfile-alphabetical/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [justfile alphabetical recipe order](https://github.com/casey/just) wrapper, packaged as a Nix flake.

Checks that justfile recipes are in alphabetical order. Skips `[private]` recipes. Exits 0 when no justfiles are found.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-justfile-alphabetical
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-justfile-alphabetical = {
  url = "github:pr0d1r2/nix-lefthook-justfile-alphabetical";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-justfile-alphabetical.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    justfile-alphabetical:
      glob: "justfile"
      run: timeout ${LEFTHOOK_JUSTFILE_ALPHABETICAL_TIMEOUT:-30} lefthook-justfile-alphabetical {staged_files}
```

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_JUSTFILE_ALPHABETICAL_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-justfile-alphabetical  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
