# Extract recipe names from a justfile in file order.
# Consumed by lefthook-justfile-alphabetical.sh, which then
# asserts the emitted list is already LC_ALL=C sorted.

/^[[:space:]]*#/ { next }
/^\[private\]/  { skip_next = 1; next }
/^[a-z][a-zA-Z0-9_-]*([[:space:]]+[a-zA-Z0-9_]+)*:/ {
    if (skip_next) { skip_next = 0; next }
    name = $0
    sub(/:.*/, "", name)
    sub(/[[:space:]].*/, "", name)
    if (name == "default") next
    print name
}
