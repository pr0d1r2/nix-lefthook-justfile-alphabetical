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
