# Build playbook

How to build the site once the design brief is agreed. Read `gotchas.md` before
adding any registry component — several failure modes there will cost you an
hour each if you meet them cold.

---

## 1. Write the brief first

Before any component, write `DESIGN-BRIEF.md` at the project root capturing every
answer from the interview. Show it to the user and get confirmation.

```markdown
# Design brief
Visual direction · Motion intensity · Theme · Colour (or: deferred)
Typography · Page structure · Scroll mechanics · Reduced-motion policy
Sections (in order) · Component sourcing · Detail depth · Hero treatment
Audience · Copy tone · Content source · Deployment target
```

It is the reference you build against and the thing you diff against when the
user says "that's not what I meant." Update it when direction changes.

---

## 2. Establish the design system before components

In this order — getting it backwards means retrofitting every component later.

1. **Tokens.** Define the palette in `globals.css` as CSS variables on `:root`
   plus a dark override. If colour was deferred, use the shadcn neutral tokens
   untouched. **Never hardcode a hex in a component** — that is what makes a
   later palette swap a one-file change instead of a sweep.
2. **Type scale.** Load fonts via `next/font`. Variable fonts: expose the axes as
   CSS variables so motion can animate them. Set the scale as tokens
   (`--step--1` … `--step-5`), not ad-hoc `text-*` picks per component.
3. **Spacing and rhythm.** Pick a section padding rhythm and a max content width
   once; reuse them everywhere.
4. **Motion primitives.** Build the shared pieces up front — a `Reveal` wrapper,
   a section shell, any scroll-scrub hook. Every section then composes them
   instead of hand-rolling its own transition.

---

## 3. Content before layout

If porting from an existing site, extract content to structured JSON in
`src/data/` first (`identity`, `experience`, `projects`, `skills`, …). Components
read from data — never inline prose into JSX. This keeps copy edits away from
layout code and makes rewriting for a different audience a data-only change.

For a JS-rendered source site, `WebFetch` returns almost nothing — clone the repo
and read the source data instead.

---

## 4. Build order

1. `layout.tsx` — fonts, metadata, theme provider
2. Design tokens in `globals.css`
3. Shared primitives — `Reveal`, `Section`, scroll hooks
4. Hero *(usually the most motion-heavy; prove the technique here first)*
5. Remaining sections in the brief's order
6. Navigation and theme toggle
7. Polish — focus states, reduced-motion fallbacks, metadata, favicon, OG image

Run `npx tsc --noEmit` as you go. Run `npm run build` before declaring anything
done — it catches module resolution and RSC boundary errors that `tsc` misses.

---

## 5. Motion

- Use the `/motion` skill and Motion MCP if the user has run `npx motion-ai`.
  If they haven't, say so rather than guessing at the current API.
- `"use client"` on anything using hooks or `motion` components.
- Import `{ motion }` from `motion/react` in client components;
  `motion/react-client` is for server components only.
- **Always honour `prefers-reduced-motion`** unless the user explicitly said to
  ignore it. `useReducedMotion()` from `motion/react`.
- Scroll-scrub and pinning: `useScroll` + `useTransform`. Keep the pinned element
  `position: sticky` rather than fighting scroll position with JS.
- Animate `transform` and `opacity`. Animating layout properties (width, height,
  top) causes jank — use `layout` transitions instead.

### GSAP, alongside Motion

- Load the matching `gsap-*` skill before writing GSAP code — `gsap-core`,
  `gsap-timeline`, `gsap-scrolltrigger`, `gsap-plugins`, `gsap-react` for
  `useGSAP` and cleanup specifically. Don't recall the API from memory.
- **Never both engines on one element** — see `gotchas.md`'s decision rule.
  Motion for React-state-driven work, GSAP for timeline choreography or a
  plugin Motion doesn't have (`SplitText`, `Flip`, `Draggable`, `MorphSVG`,
  `ScrollSmoother`).
- For a **signature moment** the design brief calls out specifically (a hero
  effect, one standout scroll interaction) where the `gsap-*` skills' API
  knowledge doesn't cover the *technique* you need, check
  [Codrops](https://tympanus.net/codrops/) for a reference implementation
  before improvising — but reimplement against this project's own
  data/tokens, don't copy source wholesale (`gotchas.md` has the copyright
  note). Reach for this on the one or two sections that actually warrant it,
  not as a first move on every section.
- **Before reaching for any registry to fill a signature moment, check
  `references/registry-routing.md`.** Sora UI, Componentry, and React Bits
  all plausibly cover "polished animated component" territory — the routing
  table assigns each to a specific niche (Sora UI: text/scroll effects built
  on Motion+GSAP; Componentry: reference-only one-off polish; React Bits:
  cursor/micro-interaction candy) so the choice doesn't drift section to
  section.

### Lenis (smooth scroll)

- Wire it up **once, at the app root**, before building any scroll-driven
  section — not after. `<ReactLenis root>` from `lenis/react`, import
  `lenis/dist/lenis.css` once.
- If GSAP ScrollTrigger or Motion's `useScroll` are already in use anywhere,
  they need explicit Lenis wiring or they'll desync — see `gotchas.md` for
  the exact `lenis.on('scroll', ScrollTrigger.update)` / `gsap.ticker.add`
  pattern. Do this in the same pass as adding Lenis, not as an afterthought.
- Only relevant at Heavy motion intensity per the design brief — don't add it
  reflexively to every full-preset project.

### Vanta (animated backgrounds)

- Client-only: `"use client"` component, initialize inside `useEffect`, never
  at module scope.
- Always return a cleanup function that calls `.destroy()` on the effect
  instance — an undestroyed Vanta instance leaks a WebGL context on
  navigation.
- Background-only — it fills the hero/footer canvas, not foreground UI
  motion. If a design brief calls for both an animated background *and*
  foreground text motion in the same section, Vanta handles the background
  layer, Motion/GSAP handle the foreground layer — don't try to make one
  library do both.

---

## 6. Verification — and its limits

**In the Claude Code browser pane you cannot verify visuals.** The pane does not
composite frames: `requestAnimationFrame` never runs and `ResizeObserver` never
fires. Consequences:

- Bklit / visx charts render as empty `<div>`s with zero SVG — `ParentSize`
  reports 0×0 and the chart bails below 10px. **This is not a bug in your code.**
- Motion scroll-reveals (`whileInView`, `useInView`) never trigger.
- `computer{action:"screenshot"}` fails with a compositing error.

What you *can* do, and should:

```bash
npx tsc --noEmit          # types
npm run build             # module resolution + RSC boundaries
```

Then via the browser tools: `get_page_text` and `read_page` to confirm content
and structure, `preview_logs` for server errors, `read_console_messages` for
client errors.

`preview_logs` returns the **entire dev-server session buffer**, including errors
you already fixed. Restart the preview server for a clean read before concluding
anything is broken.

**Tell the user plainly that motion and charts are unverified** and need their
eyes in a real browser. Do not describe animations as working when you have not
seen them.

---

## 7. Deployment

| Target | Requirement |
|---|---|
| Vercel | Nothing special; full Next.js feature set |
| GitHub Pages | `output: "export"` in `next.config.ts`, `images.unoptimized: true`, no route handlers / ISR / runtime server work |
| Cloudflare / Netlify | Adapter-dependent — check before relying on server features |

If deployment is undecided, build export-safe by default. Retrofitting static
export onto a site that leans on server features is a rewrite.

---

## 8. After the first build

The build doesn't end when `npm run build` passes — it hands off to
**`references/section-editing.md`**. Report what's done, flag anything
unverifiable per §6, and expect the next message to name a section, report a
bug, or point at an example to replicate. That's Phase 4, not a new project.
