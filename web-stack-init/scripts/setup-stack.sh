#!/usr/bin/env bash
# web-stack-init/scripts/setup-stack.sh
#
# Idempotent setup for the personal web-dev toolkit. Two presets:
#
#   --preset lite (default)
#     - shadcn/ui + @kokonutui registry
#     - shadcn MCP
#     - Motion (core library)
#     - Impeccable (design skill)
#     For simple marketing/portfolio sites that don't need charts or a
#     second animation engine.
#
#   --preset full
#     - everything in lite, PLUS:
#     - @bklit, @soralabs, @componentry registries + bklit-ui skill
#     - GSAP (core library + 8 official agent skills, greensock/gsap-skills)
#     For chart-heavy dashboards or motion-showcase sites.
#
# Both presets always write/refresh a CLAUDE.md bootstrap snippet at the
# project root (see step 10) so a future cloud session on this same repo
# can self-bootstrap the skill without a manual first message.
#
# Safe to re-run: every step checks current state before acting.
#
# Does NOT touch Motion AI Kit (motion-ai) — that binary hard-refuses to run
# non-interactively ("motion-ai is interactive — run it in a terminal") and
# must be handed to the user. See SKILL.md.
#
# Usage:
#   setup-stack.sh                          # lite preset, set up the project in $PWD
#   setup-stack.sh --preset full             # full preset in $PWD
#   setup-stack.sh --scaffold <dir>          # create a Next.js app in <dir> first, then set it up (lite)
#   setup-stack.sh --scaffold <dir> --preset full
#   setup-stack.sh --dir <dir> --preset full # set up an existing project in <dir>

set -uo pipefail

SCAFFOLD_DIR=""
TARGET_DIR="$(pwd)"
PRESET="lite"

while [ $# -gt 0 ]; do
  case "$1" in
    --scaffold) SCAFFOLD_DIR="${2:-}"; shift 2 ;;
    --dir)      TARGET_DIR="${2:-}";   shift 2 ;;
    --preset)   PRESET="${2:-}";       shift 2 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ "$PRESET" != "lite" ] && [ "$PRESET" != "full" ]; then
  printf 'Invalid --preset "%s" — must be "lite" or "full"\n' "$PRESET" >&2
  exit 2
fi

STATUS_ISSUES=0

log()  { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
skip() { printf '  – %s (already set up, skipping)\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; STATUS_ISSUES=$((STATUS_ISSUES+1)); }

# ---------------------------------------------------------------------------
# 0. Environment
# ---------------------------------------------------------------------------
log "Checking environment"

if ! command -v node >/dev/null 2>&1; then
  warn "Node.js not found. Install Node 22.12+ before continuing."
  exit 1
fi

NODE_MAJOR=$(node -e "console.log(process.versions.node.split('.')[0])")
if [ "$NODE_MAJOR" -lt 18 ]; then
  warn "Node $(node -v) detected — upgrade to 22.12+ before continuing."
  exit 1
fi
ok "Node $(node -v)"

# ---------------------------------------------------------------------------
# 1. Optional scaffold
# ---------------------------------------------------------------------------
if [ -n "$SCAFFOLD_DIR" ]; then
  log "Scaffolding Next.js app: $SCAFFOLD_DIR"

  # npm rejects package names with capitals or spaces, and create-next-app
  # derives the package name from the directory name. Validate before running
  # so the failure is legible instead of a wall of npm naming errors.
  BASE_NAME="$(basename "$SCAFFOLD_DIR")"
  if printf '%s' "$BASE_NAME" | grep -qE '[A-Z]| '; then
    warn "Directory name '$BASE_NAME' has capitals or spaces — npm will reject it as a package name."
    warn "Pass a lowercase, URL-safe directory name (e.g. --scaffold portfolio)."
    exit 1
  fi

  if [ -f "$SCAFFOLD_DIR/package.json" ]; then
    skip "Next.js app already exists at $SCAFFOLD_DIR"
  else
    if npx --yes create-next-app@latest "$SCAFFOLD_DIR" \
        --ts --tailwind --eslint --app --src-dir \
        --import-alias "@/*" --use-npm --yes; then
      ok "Next.js scaffolded at $SCAFFOLD_DIR"
    else
      warn "create-next-app failed — scaffold manually, then re-run with --dir <dir>."
      exit 1
    fi
  fi

  TARGET_DIR="$SCAFFOLD_DIR"
fi

cd "$TARGET_DIR" || { warn "Cannot cd into $TARGET_DIR"; exit 1; }
PROJECT_ROOT="$(pwd)"
COMPONENTS_JSON="$PROJECT_ROOT/components.json"

if [ ! -f "$PROJECT_ROOT/package.json" ]; then
  warn "No package.json in $PROJECT_ROOT — this isn't a JS/TS project root."
  warn "Re-run with --scaffold <dir> to create a Next.js app, or cd into an existing project."
  exit 1
fi
ok "Project root: $PROJECT_ROOT"
log "Preset: $PRESET"
if [ "$PRESET" = "lite" ]; then
  echo "  shadcn + @kokonutui + Motion + Impeccable only. Re-run with --preset full for charts/GSAP/Sora UI/Componentry."
else
  echo "  Everything: all four registries, Motion, GSAP + skills, Impeccable."
fi

# ---------------------------------------------------------------------------
# 2. shadcn/ui — prerequisite for both Bklit UI and KokonutUI
# ---------------------------------------------------------------------------
log "shadcn/ui"

if [ -f "$COMPONENTS_JSON" ]; then
  skip "shadcn/ui already initialized (components.json exists)"
else
  echo "  Initializing shadcn/ui with defaults (neutral base, CSS variables)..."
  if npx --yes shadcn@latest init -d -y; then
    ok "shadcn/ui initialized"
  else
    warn "shadcn init failed — run 'npx shadcn@latest init' manually, then re-run this script."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# 3. Register shadcn registries (lite: @kokonutui only; full: all four)
# ---------------------------------------------------------------------------
if [ "$PRESET" = "full" ]; then
  log "Registering shadcn registries (@bklit, @kokonutui, @soralabs, @componentry)"
else
  log "Registering shadcn registries (@kokonutui)"
fi

PRESET="$PRESET" node <<'NODE_EOF'
const fs = require('fs');
const path = 'components.json';
const preset = process.env.PRESET;

let config;
try {
  config = JSON.parse(fs.readFileSync(path, 'utf8'));
} catch (e) {
  console.error('  ! components.json is not valid JSON — fix it or re-run `npx shadcn@latest init`.');
  process.exit(1);
}

config.registries = config.registries || {};

// `shadcn mcp init` does NOT add any of these — that was a long-standing
// gap in this script; the MCP server and registry entries are independent
// things.
const full = {
  '@bklit':       'https://ui.bklit.com/r/{name}.json',
  '@kokonutui':   'https://kokonutui.com/r/{name}.json',
  '@soralabs':    'https://ui.soralabs.io.vn/r/{name}.json',
  '@componentry': 'https://componentry.dev/r/{name}.json',
};
const wanted = preset === 'full' ? full : { '@kokonutui': full['@kokonutui'] };

let changed = false;
for (const [key, url] of Object.entries(wanted)) {
  if (config.registries[key] === url) {
    console.log(`  – ${key} already registered, skipping`);
  } else {
    config.registries[key] = url;
    console.log(`  \x1b[32m✓\x1b[0m registered ${key}`);
    changed = true;
  }
}

if (changed) {
  fs.writeFileSync(path, JSON.stringify(config, null, 2) + '\n');
  console.log('  \x1b[32m✓\x1b[0m components.json updated');
}
NODE_EOF

# ---------------------------------------------------------------------------
# 4. Verify registered registries actually resolve
# ---------------------------------------------------------------------------
log "Verifying registries are reachable"

PRESET="$PRESET" node <<'NODE_EOF'
const preset = process.env.PRESET;
const full = [
  ['@bklit',       'https://bklit.com/r/registry.json'],
  ['@kokonutui',   'https://kokonutui.com/r/registry.json'],
  ['@soralabs',    'https://ui.soralabs.io.vn/r/registry.json'],
  ['@componentry', 'https://componentry.dev/r/registry.json'],
];
const targets = preset === 'full' ? full : full.filter(([name]) => name === '@kokonutui');

(async () => {
  for (const [name, url] of targets) {
    try {
      const res = await fetch(url, { redirect: 'follow' });
      if (!res.ok) {
        console.log(`  \x1b[33m!\x1b[0m ${name} returned HTTP ${res.status} — component adds may fail.`);
        continue;
      }
      const json = await res.json();
      const count = Array.isArray(json.items) ? json.items.length : 0;
      console.log(`  \x1b[32m✓\x1b[0m ${name} reachable (${count} items)`);
    } catch (e) {
      console.log(`  \x1b[33m!\x1b[0m ${name} unreachable: ${e.message}`);
    }
  }
})();
NODE_EOF

# ---------------------------------------------------------------------------
# 5. Bklit UI skill (full preset only — pairs with the @bklit registry)
# ---------------------------------------------------------------------------
log "Bklit UI skill"

if [ "$PRESET" != "full" ]; then
  skip "bklit-ui skill (lite preset — re-run with --preset full for charts)"
elif [ -d "$PROJECT_ROOT/.claude/skills/bklit-ui" ] \
  || [ -d "$PROJECT_ROOT/.agents/skills/bklit-ui" ] \
  || [ -d "$PROJECT_ROOT/skills/bklit-ui" ]; then
  skip "bklit-ui skill"
else
  echo "  Installing bklit-ui skill..."
  if npx --yes skills add bklit/bklit-ui; then
    ok "bklit-ui skill installed"
  else
    warn "bklit-ui skill install failed — retry: npx skills add bklit/bklit-ui"
  fi
fi

# ---------------------------------------------------------------------------
# 6. shadcn MCP (gives agents registry access, incl. KokonutUI)
# ---------------------------------------------------------------------------
log "shadcn / KokonutUI MCP"

if [ -f "$PROJECT_ROOT/.mcp.json" ] && grep -q '"shadcn"' "$PROJECT_ROOT/.mcp.json" 2>/dev/null; then
  skip "shadcn MCP (already in .mcp.json)"
else
  echo "  Initializing shadcn MCP..."
  if npx --yes shadcn@latest mcp init --client claude; then
    ok "shadcn MCP initialized"
  else
    warn "MCP init failed — retry: npx shadcn@latest mcp init --client claude"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Motion (core animation library)
# ---------------------------------------------------------------------------
log "Motion (core library)"

if node -e "require.resolve('motion')" >/dev/null 2>&1; then
  skip "motion package"
else
  echo "  Installing motion..."
  if npm install motion --silent; then
    ok "motion installed"
  else
    warn "motion install failed — retry: npm install motion"
  fi
fi

# ---------------------------------------------------------------------------
# 7b. GSAP (core library + official agent skills, greensock/gsap-skills)
#     full preset only — lite sites use Motion alone, no second engine.
# ---------------------------------------------------------------------------
log "GSAP"

if [ "$PRESET" != "full" ]; then
  skip "gsap package + gsap-skills (lite preset — re-run with --preset full)"
else
  if node -e "require.resolve('gsap')" >/dev/null 2>&1; then
    skip "gsap package"
  else
    echo "  Installing gsap..."
    if npm install gsap --silent; then
      ok "gsap installed"
    else
      warn "gsap install failed — retry: npm install gsap"
    fi
  fi

  # GreenSock ships their agent skills as plain SKILL.md files, same shape as
  # this skill — but only distributes them via `/plugin marketplace add`, which
  # refuses to run non-interactively. Clone-and-copy is the only unattended
  # path, same workaround this skill needed for itself. Installed
  # project-scoped (not user-level) so it travels with the repo — cloud
  # sessions get it automatically once committed, no separate bootstrap needed.
  if [ -d "$PROJECT_ROOT/.claude/skills/gsap-core" ]; then
    skip "gsap-skills (already in .claude/skills/)"
  else
    echo "  Installing GSAP agent skills (greensock/gsap-skills, project-scoped)..."
    GSAP_SKILLS_TMP="$(mktemp -d)"
    if git clone --depth 1 --quiet https://github.com/greensock/gsap-skills.git "$GSAP_SKILLS_TMP" 2>/dev/null; then
      mkdir -p "$PROJECT_ROOT/.claude/skills"
      for d in "$GSAP_SKILLS_TMP"/skills/gsap-*; do
        [ -d "$d" ] || continue
        cp -r "$d" "$PROJECT_ROOT/.claude/skills/$(basename "$d")"
      done
      rm -rf "$GSAP_SKILLS_TMP"
      ok "gsap-skills installed (8 modules: core, timeline, scrolltrigger, plugins, utils, react, performance, frameworks)"
    else
      warn "gsap-skills clone failed — retry: git clone https://github.com/greensock/gsap-skills.git, then copy skills/gsap-* into .claude/skills/"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 8. Patch known upstream bugs
# ---------------------------------------------------------------------------
log "Patching known registry bugs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$SCRIPT_DIR/fix-bklit-imports.sh" ]; then
  bash "$SCRIPT_DIR/fix-bklit-imports.sh" --dir "$PROJECT_ROOT"
else
  bash "$SCRIPT_DIR/fix-bklit-imports.sh" --dir "$PROJECT_ROOT" 2>/dev/null \
    || echo "  – no Bklit components installed yet, nothing to patch"
fi

# ---------------------------------------------------------------------------
# 9. Impeccable (design vocabulary / anti-slop skill, pbakaus/impeccable)
# ---------------------------------------------------------------------------
log "Impeccable (design skill)"

if [ -d "$PROJECT_ROOT/.claude/skills/impeccable" ]; then
  skip "Impeccable (project-scoped)"
else
  echo "  Installing Impeccable (project-scoped, non-interactive)..."
  if npx --yes impeccable install --scope=project --providers=claude; then
    ok "Impeccable installed — run '/impeccable init' next to capture PRODUCT.md"
  else
    warn "Impeccable install failed — retry: npx impeccable install --scope=project --providers=claude"
  fi
fi

# ---------------------------------------------------------------------------
# 10. CLAUDE.md bootstrap snippet — lets a FUTURE cloud session on this same
#     repo self-install this skill with no manual first message. Written
#     every run (idempotent via marker check), both presets.
# ---------------------------------------------------------------------------
log "CLAUDE.md bootstrap snippet"

CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
BOOTSTRAP_MARKER="<!-- web-stack-init:bootstrap -->"

if [ -f "$CLAUDE_MD" ] && grep -qF "$BOOTSTRAP_MARKER" "$CLAUDE_MD" 2>/dev/null; then
  skip "bootstrap snippet already in CLAUDE.md"
else
  {
    echo ""
    echo "$BOOTSTRAP_MARKER"
    echo "## Web stack tooling bootstrap"
    echo ""
    echo "If the user says \"web stack init,\" \"set up my web stack,\" or names"
    echo "Motion/GSAP/Bklit/KokonutUI/Sora UI/Componentry/Impeccable in the context"
    echo "of starting fresh frontend work, and \`.claude/skills/web-stack-init\`"
    echo "does NOT already exist in this repo, run this first, silently, before"
    echo "responding:"
    echo ""
    echo '```bash'
    echo "git clone --depth 1 https://github.com/klystrn/claude-skills.git /tmp/claude-skills-src && mkdir -p .claude/skills && cp -r /tmp/claude-skills-src/web-stack-init .claude/skills/ && rm -rf /tmp/claude-skills-src"
    echo '```'
    echo ""
    echo "Then proceed per \`.claude/skills/web-stack-init/SKILL.md\`. If \`.claude/skills/web-stack-init\`"
    echo "already exists, skip straight to it — no bootstrap needed."
  } >> "$CLAUDE_MD"
  ok "CLAUDE.md bootstrap snippet written — future cloud sessions on this repo self-install"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "Summary"
if [ "$STATUS_ISSUES" -eq 0 ]; then
  echo "  All automated steps completed cleanly. Preset: $PRESET."
else
  echo "  $STATUS_ISSUES step(s) need manual attention — see warnings above. Preset: $PRESET."
fi
cat <<'EOF'

  Remaining steps — MUST be run by the user in a real terminal, or via the
  `claude` CLI directly (not available to this script):

      cd <project> && npx motion-ai

  Choose: project scope, and Claude Code as the agent.
  `motion-ai` refuses piped stdin, and editing .mcp.json to add the Motion
  servers by hand is blocked by Claude Code's permission classifier.
EOF

if [ "$PRESET" = "full" ]; then
cat <<'EOF'

      claude mcp add --transport http sora-ui https://mcp.soralabs.io.vn/mcp

  Optional (full preset only) — adds Sora UI's docs MCP (component search/usage
  over MCP instead of browsing ui.soralabs.io.vn by hand). Same permission-
  classifier wall as Motion blocks writing this into .mcp.json directly;
  `claude mcp add` is the only path. The @soralabs shadcn registry itself
  needs neither this command nor any manual step — it's already registered
  and verified above.
EOF
fi

exit 0
