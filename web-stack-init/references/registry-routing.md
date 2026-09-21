# Registry routing

The stack now has five component registries, two animation engines, two
single-purpose libraries, and one reference-only site. Left to per-request
judgment, that's decision drift — the same kind of need gets served
differently build to build, and every new addition makes it worse, not
better. This table exists to stop that: **one category, one owner.**

Check this table *before* reaching for any registry, at the point you're
deciding how to build a specific piece of a section — not once at Phase 2,
every time.

---

## The table

| Need | Owner | Why this one |
|---|---|---|
| Charts, data visualization | **Bklit** (`@bklit`) | Only source built specifically for charts; visx-based |
| Layout blocks — cards, page sections, marketing blocks | **KokonutUI** (`@kokonutui`) | Broadest general-purpose block library; the lite-preset default for a reason |
| Text & scroll motion effects — reveals, split-text, marquees, scroll-linked text | **Sora UI** (`@soralabs`) | Pre-built on Motion+GSAP already; don't hand-roll what it packages |
| Cursor & micro-interaction candy — click sparks, custom cursors, crosshairs | **React Bits** (`@react-bits`) | The one place this specific niche lives; always the `-TS-TW` variant |
| Signature one-off polish — magnetic dock, particle typography, 3D sliders | **Componentry** (`@componentry`) | Reference/inspect-and-customize, not drop-in — use for the one or two moments a design brief calls out by name |
| Animated WebGL/canvas backgrounds | **Vanta** | Only source that does full-canvas backgrounds; not an overlap with anything else |
| Smooth-scroll feel / inertia | **Lenis** | Infrastructure, not visual — orthogonal to every row above, wire once at the root |
| Timeline choreography, scroll pin/scrub, plugins (SplitText, Flip, Draggable, MorphSVG, ScrollSmoother) | **GSAP** | Nothing else in the stack does timeline sequencing or these plugins |
| React-state-driven reveals, simple declarative animation | **Motion** (`motion/react`) | Default for anything that's fundamentally a React state change |
| A named visual technique nothing above covers | **Codrops** (reference only) | Research a specific published technique, reimplement against this project's tokens — never copy source |
| Nothing above fits | **Hand-built** | Don't force a close-but-wrong registry component into a slot it wasn't built for |

## Decision procedure

1. **Name the need in one phrase** — "scroll-triggered text reveal," not
   "something cool for the hero."
2. **Find its row.** If two rows plausibly apply, the more specific one wins
   — a scroll-triggered text reveal is Sora UI's row even though Motion
   *could* build it by hand; Sora UI already packages that exact pattern.
3. **If nothing fits, hand-build it.** A registry component that's
   80%-right and fought into place costs more than writing 20 lines against
   the project's own tokens.
4. **Never let two rows share an owner, and never let one need have two
   owners.** If a component could plausibly come from either of two
   registries, that's a sign the table needs tightening, not that both are
   fine to use interchangeably — pick one and note why in this file.

## Adding a new registry or library later

Before adding anything new to the stack, answer one question: **what row
does it own that nothing above already owns?**

- **A genuinely empty category** (no existing row covers it) → add one row
  to this table, wire it into `setup-stack.sh` gated to the `full` preset
  (unless it's as universal a need as Motion/KokonutUI, in which case it
  goes in `lite`), and add its gotchas to `gotchas.md`.
- **Overlaps an existing owner** → don't add it, *unless* you're
  deliberately replacing the current owner (better quality, license,
  pricing, or the old one went stale/unmaintained). If you replace an
  owner, update this table's row in place and remove the old registry from
  `setup-stack.sh` and `gotchas.md` rather than letting both linger — a
  retired registry still registered in `components.json` is exactly the
  decision-drift this table exists to prevent.

This is why Magic UI, Aceternity UI, and Animate UI were rejected earlier —
all three would have collided with Sora UI's and Componentry's existing
rows with no new category to justify the addition.

## What this doesn't solve

This table make a build *consistent* — the same need routes to the same
source every time, this build or the next one. It doesn't make browsing or
selecting individual components any easier; that's still a live registry
fetch (`curl .../registry.json`) and reading names. A future searchable
picker across all five registries' combined item lists is a separate,
larger idea — see the note in `SKILL.md`'s "Future direction" section.
