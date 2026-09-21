---
name: web-stack-init
description: Sets up the personal web-dev toolkit (Motion, GSAP, Lenis, Vanta, Bklit UI, KokonutUI, Sora UI, Componentry, React Bits, Impeccable, Codrops as a reference source) in a new or existing frontend project, runs a design interview, and builds the site. Trigger at the start of ANY website, landing-page, dashboard, or frontend project, or when the user says "web stack init," "set up my web stack," "install my tools," "init my web project," "new website project," "start a new site," "my usual setup," or "my design tools." Also trigger when Motion, GSAP, Lenis, Vanta, Bklit, KokonutUI, Sora UI, Componentry, React Bits, or Impeccable are named in the context of starting fresh work. Run BEFORE writing any components.
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
  the right default (all four component registries are shadcn-based, which
  assumes a React framework with an `@/*` import alias).
- **Existing project** → check whether it's already set up. If `components.json`
  has `@kokonutui` in `registries`, `package.json` has `motion`, and `.mcp.json`
  has a shadcn entry — skip to Phase 2. (Only check for `@bklit`/`@soralabs`/
  `@componentry` too if you need to know whether it was set up **full**, not
  just whether setup happened at all — a lite project is still "already set up.")
- **Not a frontend project** (no `package.json`, or a pure backend/API repo) →
  skip this skill entirely.
- **User only wants one specific tool** → install that one directly, don't
  run the full script.

**Ask which preset, unless the user already said or it's obvious from context**
(e.g. "I need charts" → full; "quick landing page" → lite):

- **lite** *(default)* — shadcn + `@kokonutui` + Motion + Impeccable. For
  marketing sites, portfolios, landing pages — anything that doesn't need
  charts or a second animation engine.
- **full** — everything: adds `@bklit`, `@soralabs`, `@componentry`,
  `@react-bits`, GSAP + its 8 agent skills, Lenis, and Vanta (+ `three`/`p5`).
  For chart-heavy dashboards or motion-showcase sites.

Lite → full is a safe upgrade later (`--preset full`, re-run); it only adds,
never removes. Full → lite isn't scripted — nothing forces removal, so if a
project genuinely doesn't need GSAP/Bklit/Sora UI/Componentry/React Bits/
Lenis/Vanta after they were installed, just don't use them (or uninstall
manually).

Directory names with capitals or spaces will break `create-next-app` — scaffold
into a lowercase subdirectory. The script enforces this.

---

## Phase 1 — Set up the stack

One command. It is idempotent; re-running is safe. Default preset is **lite**
— pass `--preset full` once the Phase 0 question is answered, if that's the
answer.

```bash
# new project, lite (default)
bash scripts/setup-stack.sh --scaffold portfolio

# new project, full
bash scripts/setup-stack.sh --scaffold portfolio --preset full

# existing project
bash scripts/setup-stack.sh --preset full   # or omit --preset for lite
```

It scaffolds (if asked), runs `shadcn init` with defaults, registers the
preset's shadcn registries (lite: `@kokonutui` only; full: adds `@bklit`,
`@soralabs`, `@componentry`, `@react-bits`), verifies each one actually
resolves, installs the shadcn MCP, installs `motion` and Impeccable in both
presets, and — full only — installs the bklit-ui skill, `gsap` plus the
official GreenSock agent skills, `lenis`, and `vanta` (+ `three`/`p5`), and
patches the known Bklit import bug.

**Before adding any component from any registry, check
`references/registry-routing.md`.** With five registries and two animation
engines now in the stack, several of them cover overlapping ground (Sora UI,
Componentry, and React Bits all do "animated interactive components" in
different flavors) — the routing table assigns each kind of need to exactly
one source so component selection stays consistent build to build instead of
drifting by session. Check it before Phase 2's component-sourcing question
and again at each section in Phase 3, not just once.

**Sora UI (`@soralabs`)** is a registry, same pattern as Bklit/
KokonutUI — shadcn-compatible, `npx shadcn@latest add @soralabs/<name>` —
but its primitives are built on Motion *and* GSAP both, so it's the natural
place to reach once GSAP is in the stack. Every add re-prompts to overwrite
`src/lib/utils.ts` even when identical; see `gotchas.md`, it's harmless. Its
own docs MCP (`sora-ui`, separate from the shadcn MCP) is optional and hits
the same permission-classifier wall as Motion's — hand the user the `claude
mcp add` command, don't attempt to write `.mcp.json` directly.

**Componentry (`@componentry`)** is a focused registry (50+ animated components)
for polished, interactive UI — magnetic dock, particle typography, ripple
transitions, 3D sliders, and similar sophisticated effects. Backed by Vercel's
Open Source Program, it emphasizes editable source and is a perfect complement
when the ask calls for signature moments requiring more visual polish than
Sora UI's primitives or Bklit's charts alone provide.

**React Bits (`@react-bits`)** is a large registry (~205 components × 4
language/style variants each — always add the `-TS-TW` variant, see
`gotchas.md`) whose real differentiator is small interaction/cursor candy
(click sparks, custom cursors) that Sora UI and Componentry don't cover as
deeply. It genuinely overlaps the other two in places — that's exactly what
`registry-routing.md` exists to resolve, don't reach for it by default.

**Lenis** (npm package `lenis`, `lenis/react` for `<ReactLenis>`/`useLenis`)
is a smooth-scroll library, not a shadcn registry. It changes global scroll
semantics, so once it's added, both GSAP ScrollTrigger and Motion's
`useScroll` need explicit wiring to stay in sync — see `gotchas.md` before
adding it to a project that already has scroll-driven sections built.

**Vanta** (npm packages `vanta` + `three` + `p5`, installed together since
different effects need different peer deps) renders full WebGL/canvas
animated backgrounds — a genuine gap the rest of the stack doesn't fill, not
an overlap. Client-only (`"use client"` + `useEffect` init), and the effect
instance must be `.destroy()`ed on unmount or it leaks a WebGL context — see
`gotchas.md`.

**Codrops** (tympanus.net/codrops) isn't installed — it's a reference site
for GSAP technique research, not a registry or package. `WebFetch` a
specific tutorial URL when a request needs a named visual technique the
`gsap-*` skills' API knowledge alone won't produce. Treat what comes back as
technique reference to reimplement, not source to copy verbatim — see
`gotchas.md` for the copyright caveat.

**Impeccable installs cleanly everywhere, including cloud sessions** — unlike
the other steps, it needs no filesystem transplant. `npx impeccable install
--scope=project --providers=claude` fetches and writes `.claude/skills/impeccable/`
non-interactively, works identically on this machine or in a cloud sandbox, and
travels with the repo afterward since it's now committed inside `.claude/`.
After it installs, tell the user to run `/impeccable init` (or invoke it via the
Skill tool directly) to capture `PRODUCT.md` — that step does use
`AskUserQuestion`, which works fine in a cloud session.

**GSAP is both a library and 8 official agent skills**
(`greensock/gsap-skills`: core, timeline, scrolltrigger, plugins, utils, react,
performance, frameworks). The npm package (`gsap`) is trivial and free — the
whole plugin suite (ScrollTrigger, SplitText, Flip, Draggable, MorphSVG, ...)
went free when Webflow acquired GreenSock and opened it up in 2025, no license
key needed. The skills only ship via `/plugin marketplace add
greensock/gsap-skills`, which — like Impeccable's marketplace path — refuses to
run non-interactively. The script works around it exactly like this skill
works around its own cloud-portability problem: `git clone --depth 1` the repo
into a temp dir, copy `skills/gsap-*` straight into the **project's**
`.claude/skills/` (not user-level), discard the clone. Project-scoped means it
commits with the repo and a cloud session gets it automatically once pushed —
no separate bootstrap needed, unlike this skill itself.

**Motion vs. GSAP — don't run both on the same element.** Once both are
installed, `references/gotchas.md` has the decision rule for which to reach
for per case; skim it before writing new animation code once GSAP is in the
stack, not just at setup time.

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
silently overwrite `page.tsx`, React Bits' variant-naming, Lenis/ScrollTrigger/
useScroll desync, Vanta's SSR and cleanup requirements, and — importantly —
why charts and scroll animations cannot be visually verified in the Claude
Code browser pane, and what to tell the user about it.

**Check `references/registry-routing.md` before picking a source for any
given need** — which registry/library owns which kind of component, so the
choice is the same whether this is section 1 or section 8.

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
| `gsap` install failed | Retry `npm install gsap` |
| gsap-skills clone failed | Retry manually: `git clone --depth 1 https://github.com/greensock/gsap-skills.git /tmp/gsap-skills && cp -r /tmp/gsap-skills/skills/gsap-* .claude/skills/` |
| `@soralabs/... not found` | Registry entry missing from `components.json` — re-run the script |
| Sora UI add re-prompts on `utils.ts` every time | Expected — its own copy is identical, just always declared as a shared dep; safe either way |
| `@componentry/... not found` | Registry entry missing from `components.json` — re-run the script |
| `@bklit`/`@soralabs`/`@componentry`/`@react-bits`/`gsap`/`lenis`/`vanta` missing on a project that should have them | Project was set up **lite** — re-run with `--preset full` to add them, non-destructively |
| `Invalid --preset "x"` | Only `lite` or `full` are valid — check spelling |
| `@react-bits/ClickSpark not found` (bare name, no suffix) | React Bits requires a variant suffix — use `@react-bits/ClickSpark-TS-TW` |
| Vanta crashes with `window is not defined` | Missing `"use client"` or initialized outside `useEffect` — see `gotchas.md` |
| Scroll-triggered animation stopped firing after adding Lenis | ScrollTrigger/`useScroll` need explicit Lenis wiring — see `gotchas.md` |

---

## Cloud sessions

Two different portability stories:

- **Impeccable** needs nothing special — it's fetched fresh by `npx` every time
  Phase 1 runs, cloud or local, and once installed it's committed inside the
  project's `.claude/` so it travels with the repo from then on.
- **This skill itself** (`web-stack-init`) does not self-install, but Phase 1
  now solves the common case automatically. Every run — either preset —
  appends a bootstrap snippet to the project's `CLAUDE.md` (marked with
  `<!-- web-stack-init:bootstrap -->`, written once, idempotent) instructing
  any future session to clone-and-copy this skill from
  `github.com/klystrn/claude-skills` if `.claude/skills/web-stack-init` isn't
  already present. Since Claude Code reads `CLAUDE.md` automatically at
  session start, a **cloud session opened later against a repo that has
  already run Phase 1 once (locally or in an earlier cloud session)**
  self-bootstraps with no manual first message — just say "web stack init" and
  it reads the snippet and installs itself before responding.
  **The one case this doesn't cover:** a repo where Phase 1 has *never* run
  before (a brand-new empty cloud sandbox with nothing committed yet) has no
  `CLAUDE.md` to read. That first run still needs either the manual bootstrap
  command (see the `claude-skills` repo's README) or Phase 1 to have been run
  locally at least once and pushed.
- **`npx motion-ai` cannot complete in an unattended cloud session** — it
  hard-refuses non-interactive execution and needs a human choosing scope and
  agent at a real terminal. A cloud build will hit this, report it as
  blocked, and move on; either run it locally once and commit the resulting
  config, or accept the gap.
- **`gsap-skills` solves its own cloud problem, unlike this skill.** It's
  installed project-scoped via clone-and-copy (see Phase 1), so once it's
  installed once and committed, every future clone of that repo — including a
  cloud checkout — has it. No separate bootstrap repo needed, unlike
  `web-stack-init` itself.
- **`@soralabs` (Sora UI) travels for free** — it's one key in
  `components.json`, committed with everything else, no filesystem transplant
  needed. Its optional docs MCP is the exception: same as `motion-ai`, `claude
  mcp add --transport http sora-ui ...` needs a human at a real terminal and
  can't complete in an unattended cloud session — but skipping it costs
  nothing functionally, since the shadcn MCP (already configured) can still
  install `@soralabs/*` components without it.
- **`@componentry` (Componentry) travels for free** — like `@soralabs` and the
  other registries, it's one key in `components.json`, committed with
  everything else, no filesystem transplant needed.
- **`@react-bits` travels for free** — same as the other registries, one key
  in `components.json`.
- **Lenis and Vanta travel for free** — plain npm packages, committed via
  `package.json`/`package-lock.json` like `motion` or `gsap`; no special
  cloud handling needed.
- **Codrops needs nothing installed at all** — it's consulted via `WebFetch`
  at the point of need, works identically local or cloud, no portability
  story to worry about.
- **Browser-pane verification limits are environment-wide, not
  machine-wide** — no `requestAnimationFrame`, no `ResizeObserver`,
  `AnimatePresence` exits that never unmount (see `gotchas.md`). A cloud
  session hits the exact same limits; motion and chart work need a human's
  eyes regardless of where the build ran.

---

## Future direction — a searchable design-element picker

Not built, not scheduled — recorded here because it comes up. The idea: a
UI (Artifact prototype first, real app later if it earns it) that indexes
every item across all five registries, lets you browse/search/select
visually, and exports a plain list — `{component, source, intendedUse}` per
item — that Phase 2 reads instead of (or alongside) running the interview.

**Why this isn't built yet:** `registry-routing.md` + a live `curl
.../registry.json` at the point of need already gets most of the value — a
consistent, explainable "why this component" decision — without maintaining
a second, indexed catalog that goes stale the moment any of the five
registries changes (as they already have — Sora UI's item count moved from
139 to 69 between two setup runs in the same week). A picker's index is a
new source of truth to keep in sync; the routing table has none of that
because it always defers to the live registry.

**If it gets built anyway:** the export format matters more than the picker
UI itself. A small, well-scoped JSON file at the project root
(`{component, source, intendedUse}[]`) that Phase 2 can read and skip
straight to Phase 3 with is a contained addition to this skill. The picker
that produces that file is the larger, separate project — build it only
after the routing table has been used across a few real builds and still
feels like it wants a visual browser, not before.
