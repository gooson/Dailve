#!/bin/bash
# Validates TODO file naming convention
# Usage: ./scripts/hooks/validate-todo.sh [file]

PATTERN="^[0-9]{3}-(pending|ready|in-progress|done)-(p1|p2|p3)-[a-z0-9-]+\.md$"

if [ -n "$1" ]; then
    FILES=$(basename "$1")
else
    FILES=$(ls todos/*.md 2>/dev/null | xargs -I{} basename {} 2>/dev/null)
fi

if [ -z "$FILES" ]; then
    echo "No TODO files found."
    exit 0
fi

ERRORS=0
VALID=0
for file in $FILES; do
    if [[ "$file" == ".gitkeep" ]]; then
        continue
    fi
    if ! echo "$file" | grep -qE "$PATTERN"; then
        echo "INVALID: $file"
        echo "  Expected format: NNN-STATUS-PRIORITY-description.md"
        echo "  STATUS:   pending | ready | in-progress | done"
        echo "  PRIORITY: p1 | p2 | p3"
        echo "  Example:  001-ready-p1-fix-auth-bypass.md"
        echo ""
        ERRORS=$((ERRORS + 1))
    else
        VALID=$((VALID + 1))
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Valid:   $VALID"
echo "Invalid: $ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
    exit 1
fi

echo "All TODO files follow naming convention."
