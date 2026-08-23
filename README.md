# claude-skills

Reginald Tan's personal Claude Code skills, kept in one place so any
project — local or cloud — can pull the current version instead of a
stale, hand-copied one.

Currently holds:

- **`web-stack-init/`** — sets up the personal web-dev toolkit (Motion,
  Bklit UI, KokonutUI, Impeccable) in a frontend project, runs a design
  interview, builds the site, then hands off to a section-level edit loop.
  See `web-stack-init/SKILL.md`.

## Using this in a new project (local or cloud)

This repo is **private**. A cloud Claude Code session can only clone it if
it's already authenticated as you on GitHub — check that before relying on
this. If the clone below fails with a permission error in a cloud session,
fall back to the manual option further down.

From the target project's root, run:

```bash
git clone --depth 1 https://github.com/klystrn/claude-skills.git /tmp/claude-skills-src \
  && mkdir -p .claude/skills \
  && cp -r /tmp/claude-skills-src/web-stack-init .claude/skills/ \
  && rm -rf /tmp/claude-skills-src
```

That copies `web-stack-init` into the project's own `.claude/skills/`,
project-scoped — from then on it's committed with the rest of the repo and
needs no further bootstrap.

### If the clone fails (private repo, no cloud auth)

Two options:

1. **Make this repo public.** Its contents are build-tooling instructions,
   not sensitive — the tradeoff is discoverability, not security. Flip
   visibility in GitHub repo settings, no other change needed.
2. **Use a personal access token.** Generate a fine-grained PAT scoped to
   just this repo (read-only), then clone with:
   ```bash
   git clone --depth 1 https://<TOKEN>@github.com/klystrn/claude-skills.git /tmp/claude-skills-src
   ```
   Pass the token to the cloud session as an environment variable, never
   hardcoded in a command that gets logged or committed.

## Updating

Edit the skill locally at `~/.claude/skills/web-stack-init`, copy the
changes back into this repo, commit, and push. Projects that already copied
an older version won't auto-update — re-run the bootstrap command in each
project that needs the refresh.

## Adding another skill

Same pattern: drop a new top-level folder in this repo (e.g. `my-skill/`),
and reference it in the bootstrap command by name.
