# Design interview

Run this AFTER the stack is set up and BEFORE writing a single component.

Use `AskUserQuestion`, batched **4 questions per call**. Do not ask all of these —
pick what's actually undetermined for this project, and skip anything the user
already stated. A question whose answer you could confidently guess from context
is a question you should not ask.

Order matters: Round 1 fixes the identity, Round 2 fixes the execution,
Round 3 fixes the content, Round 4 only if genuinely still ambiguous.

Record every answer into a written brief (see `build-playbook.md`) before building.

---

## Round 1 — Identity

**Visual direction**
- Editorial / typographic — whitespace, restrained colour, content-first
- Bold & expressive — large type, strong colour, heavy motion
- Terminal / technical — mono type, dense data, chart-heavy
- Soft / organic — rounded, warm, gradient-led
- Brutalist — raw borders, exposed structure, deliberate friction

**Motion intensity** *(drives how much animation work follows)*
- Minimal — essentially static, motion only where it aids comprehension
- Subtle — fade/slide reveals on scroll
- Moderate — scroll reveals plus a few signature moments
- Heavy — scroll-linked animation, layout transitions, parallax

**Motion engine** *(only ask when GSAP is installed alongside Motion, and only
at Moderate/Heavy intensity — Minimal/Subtle rarely needs more than Motion)*
- Motion only — declarative, React-state-driven, the simpler default
- GSAP for signature moments, Motion elsewhere — timeline choreography or a
  specific plugin (SplitText, Flip, Draggable, ScrollSmoother) for one or two
  standout sections, Motion for everything else
- Let me choose per section — recommended default; see `gotchas.md`'s
  Motion-vs-GSAP rule and don't ask again per section, just apply it

**Theme**
- System + toggle (both themes designed equally)
- Dark-first with a light toggle
- Light-first with a dark toggle
- Single committed theme, no toggle

**Colour**
- Ask for a direction, or offer to defer.
- If deferred: build on **neutral shadcn tokens only**, never hardcode a hex.
  Then a palette swap is a one-file change in `globals.css`.
- If chosen: get one accent, confirm it clears contrast in BOTH themes.

---

## Round 2 — Execution

**Typography**
- Oversized grotesk + mono counterpoint for data/labels
- Editorial serif display against technical content
- All-mono, committed terminal aesthetic
- Variable-weight display, animated across weights/widths

**Page structure**
- Single long scroll
- Scroll + detail routes (e.g. per project)
- Separate routes per section with animated transitions
- Horizontal / sectioned scroll

**Scroll mechanics** *(only if they picked heavy motion or sectioned scroll)*
- Vertical wheel → horizontal pan
- Full-page snap sections
- Hybrid — vertical page, specific sections are horizontal rails
- Pinned scroll-scrub — sections pin while scroll drives an animation

**Reduced motion**
- Full fallback — respect `prefers-reduced-motion`, all content still reachable
- Reduce, don't remove — keep fades, drop parallax and scrub
- Ignore it *(discourage this; say so plainly)*

---

## Round 3 — Content & components

**Sections to include** — `multiSelect: true`. Offer what fits the project type;
for a portfolio that's typically: hero, about, experience/timeline, projects,
skills, credentials/awards, testimonials, contact, blog/writing, photography.

**Component sourcing**
- Charts as a feature — Bklit charts central to the design
- Light accents — mostly hand-built, registry components where they earn it
- KokonutUI-forward — lean on its blocks for cards/sections/interactions
- Sora UI-forward — its Motion/GSAP-driven primitives (text effects, scroll
  interactions) for the signature moments, hand-built or lighter registries elsewhere
- Whatever fits best per section — no quota either way

**Detail depth** *(portfolios and project-led sites)*
- Cards only
- Cards + in-page expandable detail
- Full case-study routes
- Cards with charts/data inline, no drill-down

**Hero treatment**
- Single bold statement, held still
- Rotating / cycling lines
- Kinetic type as the signature moment
- Data or chart-led hero
- Image / video-led

---

## Round 4 — Only if still ambiguous

**Audience** — recruiters, domain-specific firms, peers/engineers, general
**Copy tone** — verbatim from source, tighten but keep voice, rewrite bolder, rewrite for audience
**Content source** — existing site/repo to port, supplied file, written fresh from an interview
**Deployment** — Vercel, GitHub Pages *(forces static export — flag this)*, Cloudflare/Netlify, undecided

---

## Rules

- **Never ask what you can verify.** Check the repo, the existing site, `package.json` first.
- **Deployment shapes architecture.** GitHub Pages means `output: "export"` — no
  server components doing runtime work, no route handlers, no ISR. Settle it before
  building anything server-side, or build export-safe by default.
- **Colour deferral is fine, silent hardcoding is not.** If colour is deferred,
  say plainly that you are building on neutral tokens so it can be swapped later.
- **Recommend, don't survey.** Put your recommendation first and label it.
- **Stop after the interview.** Write the brief, show it, get confirmation, then build.
