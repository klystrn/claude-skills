#!/usr/bin/env bash
# web-stack-init/scripts/fix-bklit-imports.sh
#
# Patches a known upstream bug in the @bklit registry.
#
# `chart-loading-label.tsx` ships with:
#     import { ShimmeringText } from "../components/shimmering-text";
# which resolves to src/components/components/shimmering-text — a path that
# does not exist. The real file lands at src/components/shimmering-text.tsx.
#
# The bad import is re-written every time ANY @bklit component is added
# (because the registry re-emits its shared files), so this must be re-run
# after EVERY `npx shadcn@latest add @bklit/...` — not just once at setup.
#
# Idempotent and safe to run when no Bklit components are installed.
#
# Usage: fix-bklit-imports.sh [--dir <project-root>]

set -uo pipefail

TARGET_DIR="$(pwd)"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="${2:-}"; shift 2 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

cd "$TARGET_DIR" || exit 1

CHARTS_DIR="src/components/charts"
LABEL_FILE="$CHARTS_DIR/chart-loading-label.tsx"

if [ ! -f "$LABEL_FILE" ]; then
  echo "  – no Bklit chart components installed, nothing to patch"
  exit 0
fi

PATCHED=0

if grep -q '"\.\./components/shimmering-text"' "$LABEL_FILE" 2>/dev/null; then
  # Make sure the dependency it wants actually exists before rewiring to it.
  if [ ! -f "src/components/shimmering-text.tsx" ]; then
    echo "  installing missing dependency @bklit/shimmering-text..."
    npx --yes shadcn@latest add @bklit/shimmering-text --yes >/dev/null 2>&1 \
      || echo "  ! could not auto-install shimmering-text — run: npx shadcn@latest add @bklit/shimmering-text"
  fi

  node -e '
    const fs = require("fs");
    const f = "src/components/charts/chart-loading-label.tsx";
    const before = fs.readFileSync(f, "utf8");
    const after = before.replace(
      /"\.\.\/components\/shimmering-text"/g,
      "\"@/components/shimmering-text\""
    );
    if (before !== after) fs.writeFileSync(f, after);
  '
  echo "  ✓ fixed broken shimmering-text import in chart-loading-label.tsx"
  PATCHED=1
fi

if [ "$PATCHED" -eq 0 ]; then
  echo "  – Bklit imports already correct"
fi

exit 0
