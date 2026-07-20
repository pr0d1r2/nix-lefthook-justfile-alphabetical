#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TEST_TMPDIR="$(mktemp -d)"

    cat > "$TEST_TMPDIR/confirm-mock.sh" <<'SH'
#!/usr/bin/env bash
echo "FRAGMENTS_DIR=$FRAGMENTS_DIR"
echo "ASSEMBLE_SCRIPT=$ASSEMBLE_SCRIPT"
echo "DETECT_SCRIPT=$DETECT_SCRIPT"
echo "SETTING_SRC=$SETTING_SRC"
echo "CONFIRM_SCRIPT=$CONFIRM_SCRIPT"
echo "CONFIRM_REV=$CONFIRM_REV"
SH
    chmod +x "$TEST_TMPDIR/confirm-mock.sh"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

@test "exports all environment variables" {
    FRAGMENTS_DIR="/test/fragments"
    ASSEMBLE_SCRIPT="/test/assemble.sh"
    DETECT_SCRIPT="/test/detect.sh"
    SETTING_SRC="/test/setting"
    CONFIRM_SCRIPT="$TEST_TMPDIR/confirm-mock.sh"
    CONFIRM_REV="abc123"
    run bash -c '
        FRAGMENTS_DIR="'"$FRAGMENTS_DIR"'" \
        ASSEMBLE_SCRIPT="'"$ASSEMBLE_SCRIPT"'" \
        DETECT_SCRIPT="'"$DETECT_SCRIPT"'" \
        SETTING_SRC="'"$SETTING_SRC"'" \
        CONFIRM_SCRIPT="'"$CONFIRM_SCRIPT"'" \
        CONFIRM_REV="'"$CONFIRM_REV"'" \
        bash app-confirm.sh
    '
    assert_success
    assert_line "FRAGMENTS_DIR=/test/fragments"
    assert_line "ASSEMBLE_SCRIPT=/test/assemble.sh"
    assert_line "DETECT_SCRIPT=/test/detect.sh"
    assert_line "SETTING_SRC=/test/setting"
    assert_line "CONFIRM_SCRIPT=$TEST_TMPDIR/confirm-mock.sh"
    assert_line "CONFIRM_REV=abc123"
}

@test "propagates exit code from CONFIRM_SCRIPT" {
    cat > "$TEST_TMPDIR/fail.sh" <<'SH'
#!/usr/bin/env bash
exit 1
SH
    chmod +x "$TEST_TMPDIR/fail.sh"
    run bash -c '
        FRAGMENTS_DIR="" \
        ASSEMBLE_SCRIPT="" \
        DETECT_SCRIPT="" \
        SETTING_SRC="" \
        CONFIRM_SCRIPT="'"$TEST_TMPDIR/fail.sh"'" \
        CONFIRM_REV="" \
        bash app-confirm.sh
    '
    assert_failure
}

@test "propagates success from CONFIRM_SCRIPT" {
    cat > "$TEST_TMPDIR/pass.sh" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    chmod +x "$TEST_TMPDIR/pass.sh"
    run bash -c '
        FRAGMENTS_DIR="" \
        ASSEMBLE_SCRIPT="" \
        DETECT_SCRIPT="" \
        SETTING_SRC="" \
        CONFIRM_SCRIPT="'"$TEST_TMPDIR/pass.sh"'" \
        CONFIRM_REV="" \
        bash app-confirm.sh
    '
    assert_success
}
