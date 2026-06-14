#!/usr/bin/env bash
# Pushes local wiki/ pages to the GitHub wiki repository.
# Run this AFTER enabling the wiki in: GitHub → Settings → Features → Wikis ✓

set -euo pipefail

WIKI_REMOTE="git@github.com:prasenjeet/macOS-Application.wiki.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"

echo "Cloning wiki repo…"
git clone "$WIKI_REMOTE" "$TMP_DIR"

echo "Copying pages…"
cp "$SCRIPT_DIR"/*.md "$TMP_DIR"/

echo "Committing…"
cd "$TMP_DIR"
git add -A
git commit -m "Update wiki pages" || echo "(nothing to commit)"
git push

echo "Done. View at: https://github.com/prasenjeet/macOS-Application/wiki"
rm -rf "$TMP_DIR"
