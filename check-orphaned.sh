#!/usr/bin/env bash
# check-orphaned.sh — Find resource files that are not referenced by any markdown file.
set -euo pipefail

ORPHANS=0

while IFS= read -r file; do
    if ! rg -qF "$file" . -t markdown 2>/dev/null; then
        echo "[Warning] Orphan file: $file"
        ORPHANS=$((ORPHANS + 1))
    fi
done < <(rg --files -T markdown -T make -g '!scripts' -g '!static')

echo "Done."
if [ $ORPHANS -gt 0 ]; then
    echo "[Error] Found $ORPHANS orphaned file(s)."
    exit 1
fi
