#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "CI reusable workflows are pinned to full commit SHAs" {
    run awk '
        /^[[:space:]]+uses:/ {
            value = $0
            sub(/^[[:space:]]*uses:[[:space:]]*/, "", value)
            sub(/[[:space:]]+#.*/, "", value)
            gsub(/[[:space:]]/, "", value)
            gsub(/"/, "", value)
            gsub(/\047/, "", value)
            if (split(value, parts, "@") != 2 || length(parts[1]) == 0 || length(parts[2]) != 40 || parts[2] !~ /^[0-9a-f]+$/) invalid = 1
            found = 1
        }
        END { exit (!found || invalid) }
    ' "$REPO_ROOT/.github/workflows/ci.yml"
    assert_success
}

@test "CI workflow pin check rejects malformed references" {
    for revision in \
        "" \
        "ABCDEF0123456789ABCDEF0123456789ABCDEF01" \
        "abcdef0123456789abcdef0123456789abcdef0" \
        "abcdef0123456789abcdef0123456789abcdef012" \
        "abcdef0123456789abcdef0123456789abcdef01@extra"; do
        printf '    uses: owner/action@%s\n' "$revision" > "$BATS_TEST_TMPDIR/workflow.yml"
        run awk '
            /^[[:space:]]+uses:/ {
                value = $0
                sub(/^[[:space:]]*uses:[[:space:]]*/, "", value)
                sub(/[[:space:]]+#.*/, "", value)
                gsub(/[[:space:]]/, "", value)
                gsub(/"/, "", value)
                gsub(/\047/, "", value)
                if (split(value, parts, "@") != 2 || length(parts[1]) == 0 || length(parts[2]) != 40 || parts[2] !~ /^[0-9a-f]+$/) invalid = 1
                found = 1
            }
            END { exit (!found || invalid) }
        ' "$BATS_TEST_TMPDIR/workflow.yml"
        assert_failure
    done
}

@test "flake exports the default package on every system" {
    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' eval \
        "$REPO_ROOT#packages" \
        --apply 'ps: builtins.all (s: ps.${s} ? default) (builtins.attrNames ps)'
    assert_success
    assert_output "true"
}

@test "locked nixpkgs contains fixed ruby and brotli versions" {
    nixpkgs_rev="$(jq -r '.nodes.nixpkgs.locked.rev' "$REPO_ROOT/flake.lock")"

    run --separate-stderr nix eval --raw \
        "github:NixOS/nixpkgs/$nixpkgs_rev#ruby.version"
    assert_success
    assert_output "3.4.12"

    run --separate-stderr nix eval --raw \
        "github:NixOS/nixpkgs/$nixpkgs_rev#brotli.version"
    assert_success
    assert_output "1.2.1"
}

@test "default package runs lefthook-justfile-alphabetical" {
    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' eval --raw \
        "$REPO_ROOT#packages" \
        --apply 'ps: (builtins.head (builtins.attrValues ps)).default.meta.mainProgram or ""'
    assert_success
    assert_output "lefthook-justfile-alphabetical"
}

@test "default package check builds and runs the wrapper" {
    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' build \
        "$REPO_ROOT#checks.x86_64-linux.package" \
        --no-link
    assert_success

    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' build \
        "$REPO_ROOT#default" \
        --no-link
    assert_success

    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' run \
        "$REPO_ROOT#default" --
    assert_success
}

@test "actionlint check includes GitHub workflows" {
    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' derivation show \
        "$REPO_ROOT#checks.x86_64-linux.actionlint"
    assert_success

    check_files="$(printf '%s\n' "$output" | jq -r '.. | objects | .env? | select(.CHECK_FILES?) | .CHECK_FILES' | head -n1)"
    assert [ -n "$check_files" ]
    assert [ -f "$check_files/.github/workflows/ci.yml" ]
}
