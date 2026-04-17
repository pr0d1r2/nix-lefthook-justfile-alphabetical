#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"

    TEST_TEMP="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "exits 0 with no arguments" {
    run lefthook-justfile-alphabetical
    assert_success
}

@test "exits 0 when no justfiles in arguments" {
    touch "$TEST_TEMP/file.txt"
    run lefthook-justfile-alphabetical "$TEST_TEMP/file.txt"
    assert_success
}

@test "skips missing files silently" {
    run lefthook-justfile-alphabetical "/nonexistent/justfile"
    assert_success
}

@test "accepts alphabetically ordered recipes" {
    cat > "$TEST_TEMP/justfile" << 'EOF'
alpha:
    bash scripts/alpha.sh

beta:
    bash scripts/beta.sh

gamma:
    bash scripts/gamma.sh
EOF
    run lefthook-justfile-alphabetical "$TEST_TEMP/justfile"
    assert_success
}

@test "detects out-of-order recipes" {
    cat > "$TEST_TEMP/justfile" << 'EOF'
beta:
    bash scripts/beta.sh

alpha:
    bash scripts/alpha.sh
EOF
    run lefthook-justfile-alphabetical "$TEST_TEMP/justfile"
    assert_failure
    assert_output --partial "out of order"
}

@test "accepts justfile with single recipe" {
    cat > "$TEST_TEMP/justfile" << 'EOF'
only-recipe:
    bash scripts/only.sh
EOF
    run lefthook-justfile-alphabetical "$TEST_TEMP/justfile"
    assert_success
}

@test "skips private recipes" {
    cat > "$TEST_TEMP/justfile" << 'EOF'
alpha:
    bash scripts/alpha.sh

[private]
zebra:
    bash scripts/zebra.sh

beta:
    bash scripts/beta.sh
EOF
    run lefthook-justfile-alphabetical "$TEST_TEMP/justfile"
    assert_success
}

@test "accepts empty justfile" {
    touch "$TEST_TEMP/justfile"
    run lefthook-justfile-alphabetical "$TEST_TEMP/justfile"
    assert_success
}
