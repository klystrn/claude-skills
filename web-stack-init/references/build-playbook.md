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
