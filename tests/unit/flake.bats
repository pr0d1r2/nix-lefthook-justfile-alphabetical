#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "flake exports the default package on every system" {
    run --separate-stderr nix --extra-experimental-features 'nix-command flakes' eval \
        "$REPO_ROOT#packages" \
        --apply 'ps: builtins.all (s: ps.${s} ? default) (builtins.attrNames ps)'
    assert_success
    assert_output "true"
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
