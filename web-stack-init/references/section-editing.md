# Section-level editing

What to do once a site has a first build standing and the user wants to refine
it — either right after Phase 3 finishes, or any time later when they come
back and say "change the hero" / "redo skills" / "this section feels off."

This is **Phase 4** of the skill. It never runs blind: touching a section
without first asking what's wrong with it produces the same guess-and-redo
loop that Phase 2 exists to avoid at the start of a build.

---

## When to enter this phase

- The user names a section directly ("remove $RTAN," "fix the nav," "redo
  skills") — enter immediately for that section, no need to ask permission.
- The user gives general feedback ("it feels too fast," "this doesn't look
  right") — ask which section(s), unless the feedback is obviously global
  (see "Site-wide issues" below).
- A first build just finished — offer this phase, don't force it. Some users
  want to look first and come back with specific notes.

## The loop, per section

1. **Ask before editing.** Batch questions with `AskUserQuestion`, same rules
   as Phase 2: max 4 per call, only what's genuinely undetermined, put a
   recommendation first. Cover whichever of these actually apply:
   - **Content** — what copy/data changes, what to add or cut
   - **Component** — keep the current mechanic, or swap it (e.g. "pinned
     scroll-scrub" → "filterable tag cloud"); which registry components, if
     any, fit
   - **Layout/mechanic** — grid vs. list vs. horizontal scroll vs. pinned
     track; how it should read on mobile
   - **Motion** — keep current treatment, intensify, simplify, or remove
   - **Scope** — is this section self-contained, or does changing it ripple
     into a numbered heading, a sibling section's cross-reference, or
     `page.tsx` import order

   Don't ask about things you can just check — read the current component
   before asking whether to change it.

2. **Implement.** Follow the same discipline as the original build: content
   in `src/data/`, no hardcoded colour, shared primitives (`Reveal`,
   `Section`, etc.) over one-off styling, `"use client"` only where hooks are
   used.

3. **Verify what's checkable.** `npx tsc --noEmit`, `npm run lint`,
   `npm run build`. Read `gotchas.md` before touching any registry component
   or re-verifying in the browser pane — the limitations there (no `rAF`, no
   `ResizeObserver`, stale console/log buffers, `AnimatePresence` exit
   blocking unmount) apply just as much mid-project as they did at the
   initial build.

4. **Update `DESIGN-BRIEF.md`** if the change reverses or meaningfully departs
   from a prior decision recorded there. The brief should stay the live
   reference, not a historical snapshot of round one.

5. **Report and move on.** Say what changed, flag anything unverifiable in
   this environment, and ask if there's another section or if this one's
   done.

## Site-wide issues — handle before going section-by-section

Some feedback isn't about one section and shouldn't be diagnosed as if it
were:

- **Navigation / chrome** (nav bar, theme toggle, scroll progress) is shared
  across every section — fix it once, globally, not per-section.
- **Pacing** ("I'm scrolling past everything too fast") is usually a token
  problem, not a component problem — check `--section-py` and any
  scroll-linked track lengths (`Pinned` `length`, a track's `vh` height)
  before touching individual sections.
- **Colour** — if deferred at Phase 2 and the user is now ready to choose, do
  that as its own pass across `globals.css`, not section by section.

## Example: how this ran in practice

A real Phase 4 pass on a portfolio site, in the order the user actually raised
things:

1. "Remove the $RTAN section" — named directly, no questions needed, just
   removed the component, its import/usage, and reflowed the section index.
2. Four questions, one batch, about the sections still standing: keep the
   hero's static kinetic statement or rotate multiple lines; keep all 6 stats
   or trim; keep the terminal-window framing on Experience or drop it; keep
   the pinned scroll-scrub on Skills or simplify it.
3. Two of those answers ("visualise stats differently," "different mechanic
   for skills") were themselves underspecified — a second round of questions
   narrowed them to specifics (a non-chart "looks cool on scroll" treatment;
   a filterable tag cloud) before any code was written.
4. Mid-implementation, the user reported two site-wide bugs (nav bar
   background not rendering, scroll pacing too fast) and one content request
   (combine Experience + Education into a single horizontal-scroll timeline)
   in one message. The bugs were fixed globally first; the content request
   became its own section rebuild.
5. The user linked two motion.dev examples ("replicate this") and left the
   *placement and content* open — "I don't know where to put it, be
   creative." That's still Phase 4: propose where it goes and what it says,
   rather than silently picking without surfacing the choice.

The throughline: name a target, ask what's actually undetermined about it,
implement, verify what's checkable, say plainly what isn't.

## Patterns worth reusing

Concrete techniques that came out of doing this once — reach for these before
reinventing them:

- **Horizontal timeline / gallery**: don't fake horizontal movement with a
  vertical-scroll-driven `x` transform pinned via `position: sticky` — build
  a real `overflow-x: auto` track with `scroll-snap-x`, and drive per-item
  motion off `useScroll({ container: containerRef, target: itemRef })`. Works
  natively with trackpad/touch; the pinned-fake-scroll version doesn't.
- **Word-by-word scroll-text reveal**: one `useScroll` on the paragraph's
  container, one `useTransform` per word mapping a slice of `[0,1]` progress
  to that word's opacity — not one scroll listener per word.
- **"Looks cool but no chart library" stat displays**: staggered baseline
  offsets (a "skyline"), blur-in on scroll-into-view, and a slightly
  different per-item scroll-parallax rate for depth — all just Motion
  primitives, no chart component needed.
- **Filterable tag/chip cloud**: `layout` + `AnimatePresence` on a
  `flex-wrap` container, sized by a data-driven strength value rather than a
  fixed set of size classes.

See also [[gotcha-bklit-registry]] and `gotchas.md` for what breaks while
implementing any of the above.
