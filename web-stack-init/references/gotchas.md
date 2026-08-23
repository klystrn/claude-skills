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
