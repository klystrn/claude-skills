---
name: web-stack-init
description: Sets up the personal web-dev toolkit (Motion, Bklit UI, KokonutUI, Impeccable) in a new or existing frontend project, runs a design interview, and builds the site. Trigger at the start of ANY website, landing-page, dashboard, or frontend project, or when the user says "set up my web stack," "install my tools," "init my web project," "new website project," "start a new site," "my usual setup," or "my design tools." Also trigger when Motion, Bklit, KokonutUI, or Impeccable are named in the context of starting fresh work. Run BEFORE writing any components.
---

# Web Stack Init

Takes a website from nothing to built — and then keeps taking edits — in five
phases:

| Phase | What happens | Who drives |
|---|---|---|
| 0 | Decide the target — scaffold new, or use existing | Ask, then act |
| 1 | Install and verify the stack | Unattended script |
| 2 | Design interview → written brief | **Ask, then STOP** |
| 3 | Build the site | You |
| 4 | Section-level edits — refine what's built | **Ask per section, then act** |

**The hard stop is between Phase 1 and Phase 2.** Never run the setup and then
continue into building. Tools are deterministic and safe to run unattended;
design direction is the user's call and they want to make it before code exists.

**Phase 4 is not a one-time step.** It's the mode you're in for the rest of
the project's life — every time the user names a section, reports a bug, or
asks for a change after the first build, you're back in Phase 4.

---

## Phase 0 — Target

Check the working directory first.

- **Empty directory** → ask what to scaffold before doing anything. Next.js is
  the right default (both component registries are shadcn-based, which assumes
  a React framework with an `@/*` import alias).
- **Existing project** → check whether it's already set up. If `components.json`
  has both `@bklit` and `@kokonutui` in `registries`, `package.json` has `motion`,
  and `.mcp.json` has a shadcn entry — skip to Phase 2.
- **Not a frontend project** (no `package.json`, or a pure backend/API repo) →
  skip this skill entirely.
- **User only wants one of the three tools** → install that one directly, don't
  run the full script.

Directory names with capitals or spaces will break `create-next-app` — scaffold
into a lowercase subdirectory. The script enforces this.

---

## Phase 1 — Set up the stack

One command. It is idempotent; re-running is safe.

```bash
# new project
bash scripts/setup-stack.sh --scaffold portfolio

# existing project
bash scripts/setup-stack.sh
```

It scaffolds (if asked), runs `shadcn init` with defaults, registers **both**
the `@bklit` and `@kokonutui` registries, verifies each one actually resolves,
installs the bklit-ui skill and shadcn MCP, installs `motion`, patches the
known Bklit import bug, and installs Impeccable project-scoped.

**Impeccable installs cleanly everywhere, including cloud sessions** — unlike
the other steps, it needs no filesystem transplant. `npx impeccable install
--scope=project --providers=claude` fetches and writes `.claude/skills/impeccable/`
non-interactively, works identically on this machine or in a cloud sandbox, and
travels with the repo afterward since it's now committed inside `.claude/`.
After it installs, tell the user to run `/impeccable init` (or invoke it via the
Skill tool directly) to capture `PRODUCT.md` — that step does use
`AskUserQuestion`, which works fine in a cloud session.

Read the output. It reports what installed, what was skipped, and what needs
manual follow-up.

### The one manual step

`npx motion-ai` (Motion AI Kit — the `/motion` skill plus hosted MCP servers)
**refuses to run non-interactively** and cannot be scripted around. Hand the user
this command:

```bash
cd <project> && npx motion-ai
```

Tell them to choose **project** scope and **Claude Code** as the agent, and that
no token or account is needed — Motion+ features unlock by signing in from the
agent afterwards. Do not attempt to add the Motion MCP servers to `.mcp.json`
yourself; the permission classifier blocks it.

If the design brief calls for heavy motion, recommend they run it *before*
Phase 3 so the Motion docs are available while building.

### Report, then stop

Summarise what landed, flag the `motion-ai` step, and move to Phase 2. Do not
install components yet — this phase sets up infrastructure, nothing more.

---

## Phase 2 — Design interview

Read `references/design-interview.md` and run it.

Batched `AskUserQuestion` calls, 4 per call, roughly three rounds: identity, then
execution, then content and components. Ask only what's genuinely undetermined —
skip anything the user already told you or you can verify from the repo.

Then write `DESIGN-BRIEF.md` at the project root, show it, and get confirmation
before building.

---

## Phase 3 — Build

Read `references/build-playbook.md` and follow it.

Design system before components; content extracted to `src/data/` before layout;
`npm run build` before calling anything done.

**Read `references/gotchas.md` before adding any registry component.** It covers
the Bklit import bug that reverts on every add, the `*-example` items that
silently overwrite `page.tsx`, and — importantly — why charts and scroll
animations cannot be visually verified in the Claude Code browser pane, and what
to tell the user about it.

---

## Phase 4 — Section-level edits

Read `references/section-editing.md` and follow it.

This is the phase you're in every time the user comes back after the first
build — naming a section to change, reporting a bug, or pointing at an
external example to replicate. Ask what's undetermined about the target
**before** editing it, same discipline as Phase 2 but scoped to one section
instead of the whole site. Distinguish site-wide issues (nav, pacing, colour)
from section-specific ones before diagnosing — see the reference for how.

---

## Cost notes

- Skills are near-zero cost idle; they only expand when triggered.
- The shadcn MCP and Motion MCP each add a focused toolset. Tool Search defers
  their schemas until used, so having both connected doesn't bloat context.
- Offer global scope for `motion-ai` only if the user works across many projects
  and says so — global means it's live in every session, relevant or not.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `components.json is not valid JSON` | Re-run `npx shadcn@latest init` to regenerate |
| `bklit-ui skill install failed` | Retry `npx skills add bklit/bklit-ui`; check network |
| MCP init failed | Retry `npx shadcn@latest mcp init --client claude`; check `claude` is on PATH |
| `motion install failed` | Retry `npm install motion` |
| "no package.json found" | Re-run with `--scaffold <lowercase-dir>` |
| `@kokonutui/... not found` | Registry entry missing from `components.json` — re-run the script |
| Bklit chart renders empty | Expected in the browser pane — see `gotchas.md` |
| Impeccable install failed | Retry `npx impeccable install --scope=project --providers=claude`; needs Node 22.12+ |

---

## Cloud sessions

Two different portability stories:

- **Impeccable** needs nothing special — it's fetched fresh by `npx` every time
  Phase 1 runs, cloud or local, and once installed it's committed inside the
  project's `.claude/` so it travels with the repo from then on.
- **This skill itself** (`web-stack-init`) does not self-install. It only
  exists as files — either at `~/.claude/skills/web-stack-init` (this
  machine only, invisible to a cloud sandbox) or committed into a project's
  `.claude/skills/web-stack-init` (travels with that repo's clone, cloud
  included). If a cloud session needs this skill, commit it into that
  project's repo, or maintain a personal skills repo and have the cloud
  session clone-and-copy it in as a first step.
- **`npx motion-ai` cannot complete in an unattended cloud session** — it
  hard-refuses non-interactive execution and needs a human choosing scope and
  agent at a real terminal. A cloud build will hit this, report it as
  blocked, and move on; either run it locally once and commit the resulting
  config, or accept the gap.
- **Browser-pane verification limits are environment-wide, not
  machine-wide** — no `requestAnimationFrame`, no `ResizeObserver`,
  `AnimatePresence` exits that never unmount (see `gotchas.md`). A cloud
  session hits the exact same limits; motion and chart work need a human's
  eyes regardless of where the build ran.
