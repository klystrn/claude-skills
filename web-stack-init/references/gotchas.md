# Gotchas

Failure modes hit in practice. Each one costs an hour if you meet it cold.

---

## Scaffolding

**npm rejects capitals and spaces in package names.** `create-next-app` derives
the package name from the directory name, so scaffolding into
`C:/Users/x/Desktop/My Project` fails with a wall of naming errors. Scaffold into
a lowercase, URL-safe subdirectory (`portfolio/`) and work from there. The setup
script validates this before running.

**Next.js 16 writes its own `AGENTS.md`/`CLAUDE.md`** warning that its APIs differ
from training data. Take it seriously — read `node_modules/next/dist/docs/` before
writing framework-level code. `next dev` re-adds the block, so committing it with
your work is the way to keep the tree clean.

---

## Bklit UI (`@bklit`)

**Broken shared import.** `chart-loading-label.tsx` imports
`"../components/shimmering-text"` → resolves to
`src/components/components/shimmering-text`, which does not exist. The real file
is `src/components/shimmering-text.tsx`.

The registry **re-emits this file on every `@bklit` add**, so the fix reverts
whenever you add another chart component. Run after *every* add:

```bash
bash scripts/fix-bklit-imports.sh --dir <project-root>
```

**`*-example` items overwrite `src/app/page.tsx`.** `npx shadcn@latest add
@bklit/area-chart-example` replaces the home page with a demo, silently. Never
add an example into a project with real work in `page.tsx`. If you need to see an
example, add it, immediately move it to a throwaway route, and delete it after.

**Component names must come from the registry index.** Guessed names 404. Fetch
the real list:

```bash
curl -sL https://bklit.com/r/registry.json
```

`ui.bklit.com` 301-redirects to `bklit.com` — `WebFetch` will not follow it
automatically and will hand you the redirect target to re-fetch.

**Charts need a real browser.** See "Verification" below.

---

## Sora UI (`@soralabs`)

**Every add re-prompts to overwrite `src/lib/utils.ts`**, even when its own
copy is byte-identical to what's already there (verified: it is — the
registry just declares `utils.ts` as a shared dependency of every component,
so the CLI always offers to write it). Safe to accept (`--overwrite`) or
decline; neither breaks anything. Don't mistake the prompt for a real
conflict.

**Component names**, like Bklit, come from the registry index, not guesswork:

```bash
curl -sL https://ui.soralabs.io.vn/r/registry.json
```

**Its own docs MCP is a separate, optional add-on** — `claude mcp add
--transport http sora-ui https://mcp.soralabs.io.vn/mcp` — distinct from the
shadcn MCP that installs components. Blocked from automation the same way
Motion's MCP servers are (writing straight to `.mcp.json` hits the
permission classifier); hand the user the command, same as `motion-ai`.

**Built on Motion and GSAP both** — most primitives are Motion, some
scroll-driven text effects are GSAP. Check which before extending a
component: don't add a GSAP animation inside a component whose surrounding
motion is Motion-driven, or the same fight-over-the-DOM-node problem below
applies inside a single file, not just across sections.

---

## KokonutUI (`@kokonutui`)

**`shadcn mcp init` does not add the registry.** The MCP server and the registry
entry are independent. Without
`"@kokonutui": "https://kokonutui.com/r/{name}.json"` in `components.json` →
`registries`, every `add @kokonutui/...` fails. The setup script now adds it.

---

## Motion

**`npx motion-ai` refuses non-interactive execution.** It exits with
`motion-ai is interactive — run it in a terminal` on piped stdin, and exposes no
flags. It must be handed to the user.

**Do not work around it by editing `.mcp.json`.** Adding the Motion hosted servers
(`https://mcp.motion.dev`, `https://mcp.motion.dev/plus`) by hand is blocked by
Claude Code's permission classifier, as is copying the skill content into
`.claude/skills/`. Surface the command and let the user run it.

**Import path depends on component type.** `motion/react` in client components,
`motion/react-client` in server components. Mixing them fails confusingly.

---

## Verification in the Claude Code browser pane

**The pane does not composite frames.** `requestAnimationFrame` never runs and
`ResizeObserver` never fires. Confirm with:

```js
new Promise(res => { let n=0; const ro=new ResizeObserver(()=>n++);
  ro.observe(document.body);
  setTimeout(()=>res({roFired:n, raf:window.__r??null}),800);
  requestAnimationFrame(()=>window.__r=true); })
```

Consequences:
- visx `ParentSize` reports 0×0 → Bklit charts render as empty `<div>`s, zero SVG.
  Bklit's *own* example fails identically. **Not a code bug.**
- Motion `whileInView` / `useInView` never fire.
- `computer{action:"screenshot"}` errors out.

**`preview_logs` AND `read_console_messages` both return the whole tab/session
buffer**, including errors already fixed. Restarting the preview server is not
enough by itself if you keep driving the same browser tab — its console buffer
persists across navigations and even across server restarts. Open a **fresh
tab** (`tabs_create`) before trusting a "no errors" read, not just a server
restart.

**`AnimatePresence` exit animations block unmounting, not just styling.**
Toggling filtered/conditional content (e.g. a `layout`/`AnimatePresence` tag
cloud) updates React state and any state-driven styling (active button, aria
attributes) correctly and verifiably. But elements mid-`exit` stay mounted
until their exit animation's completion callback fires — which depends on the
same missing `rAF`, so filtered-out items never actually leave the DOM here.
Verify the *state* (classes, aria-pressed, filtered array length in a
non-animated read) rather than the DOM node count when auditing this pattern.

Verify with `npm run build` (catches what `tsc` misses: module resolution, RSC
boundaries) plus `get_page_text` / `read_page` for content. Then tell the user
plainly that motion, charts, and exit-driven unmounts need their eyes.

---

## Motion vs. GSAP — pick one per element, never both

Once GSAP is in the stack alongside Motion, the failure mode isn't "wrong
choice," it's **two animation engines fighting over the same DOM node** —
both write directly to `transform`/`opacity`, so if Motion's React render
cycle and a GSAP tween both touch the same element, whichever wrote last wins
that frame and the other's state silently desyncs. This shows up as
animations that work in isolation and glitch the moment they're combined.

**Rule: decide per element, at the point you write it, not once globally.**
A page can use both — just never on the same node, and prefer one library
per *section* so the boundary is obvious to the next person reading the code.

Reach for **Motion** (`motion/react`) when:
- The element is already React-state-driven (conditional render, `layout`
  animation, `AnimatePresence` enter/exit) — Motion is built for this,
  GSAP fights the React render cycle here.
- It's a simple, declarative reveal — `whileInView`, hover/tap variants.
- The rest of the section already uses Motion — consistency beats a marginal
  capability gain from switching mid-section.

Reach for **GSAP** when:
- It's **timeline-heavy choreography** — many elements with precise relative
  timing/labels (`gsap.timeline()` + position parameters). Motion can do
  this but GSAP's timeline API is built for exactly this and stays readable
  at higher complexity.
- It needs a **plugin with no Motion equivalent** — `SplitText` (character/
  word/line splitting with reflow handling), `MorphSVG`, `DrawSVG`,
  `Draggable` with inertia, `Flip` (FLIP-technique layout transitions across
  arbitrary DOM changes, not just React state), `ScrollSmoother`.
- It's **imperative/vanilla-DOM territory** — canvas, WebGL hooks, or
  anything manipulating elements outside React's own tree.

**ScrollTrigger vs. Motion's `useScroll`**: both do scroll-linked animation.
Motion's `useScroll`/`useTransform` is what this project already uses for the
timeline and hero (see `build-playbook.md`'s patterns list) — keep using it
for straightforward progress-mapping. Reach for GSAP's ScrollTrigger instead
when the ask specifically needs its named features: `pin` with automatic
spacer-element handling, `scrub` with a numeric lag (not just 0/1/true),
`ScrollSmoother` for smoothed native scroll, or batch-triggering many
elements from one config object. Don't install ScrollTrigger to duplicate
something `useScroll` already does cleanly in this codebase.

**Before writing GSAP code**, load the relevant `gsap-*` skill rather than
recalling the API from memory — `gsap-core` for basic tweens, `gsap-timeline`
for sequencing, `gsap-scrolltrigger` for scroll work, `gsap-plugins` before
registering any plugin, `gsap-react` for the `useGSAP` hook and cleanup
specifically (a raw `useEffect` + manual `.kill()` is the wrong pattern once
this skill is installed — `useGSAP` handles context/cleanup correctly).

**For a technique you can't get from the `gsap-*` skills alone** — a specific
visual effect, not just an API — [Codrops](https://tympanus.net/codrops/) is
the reference site to check, particularly its
[GSAP tag](https://tympanus.net/codrops/tag/gsap/) and
[Demos hub](https://tympanus.net/codrops/hub/author/gsap/). It's not
installable and not a registry — `WebFetch` a specific tutorial URL when a
request needs a named technique (a particular scroll-mask effect, a
carousel style, an SVG-morph pattern) that a plain API lookup won't produce.

Treat what comes back as **technique reference, not source to copy
verbatim** — Codrops demos carry their own licensing per post (often
CodePen-embedded, not uniformly MIT), and the copyright rule in this skill's
system prompt already caps any single quote at under 15 words. Read the
approach, reimplement it against this project's own data/tokens/components,
and cite the source in a code comment only if it materially shaped the
technique — not as a matter of course.
