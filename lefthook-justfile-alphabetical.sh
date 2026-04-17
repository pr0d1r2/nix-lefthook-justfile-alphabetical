# shellcheck shell=bash
# Lefthook-compatible justfile alphabetical recipe order check.
# NOTE: sourced by writeShellApplication — no shebang or set needed.
# AWK_PROGRAM is set by flake.nix to the nix store path of the .awk file.

if [ $# -eq 0 ]; then
    exit 0
fi

files=()
for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        justfile | */justfile) files+=("$f") ;;
    esac
done

if [ ${#files[@]} -eq 0 ]; then
    exit 0
fi

for file in "${files[@]}"; do
    recipes="$(awk -f "$AWK_PROGRAM" "$file")"

    [ -n "$recipes" ] || continue

    sorted="$(printf '%s\n' "$recipes" | LC_ALL=C sort)"
    if [ "$recipes" != "$sorted" ]; then
        prev=""
        while IFS= read -r name; do
            if [ -n "$prev" ] && [ "$(printf '%s\n%s\n' "$prev" "$name" | LC_ALL=C sort | head -1)" != "$prev" ]; then
                printf '%s: recipes out of order: %s should come before %s\n' "$file" "$name" "$prev" >&2
                exit 1
            fi
            prev="$name"
        done <<<"$recipes"
        printf '%s: recipes out of order\n' "$file" >&2
        exit 1
    fi
done
