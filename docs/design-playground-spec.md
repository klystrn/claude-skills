# Design Playground — Technical Spec

Status: **not built**. This is a specification for a future project — a
searchable, browsable UI across every source in the `web-stack-init` tech
stack, ending in an export that Claude Code consumes to build a site. It
exists so that project can be started from an accurate model of what it's
indexing, instead of re-deriving the stack's shape from scratch.

For the *operational* version of this same information — which source to
reach for while actually building a site — see `web-stack-init/references/
registry-routing.md`. That doc is written for an agent mid-build. This one
is written for whoever builds the playground.

---

## 1. What this indexes

The stack has three fundamentally different kinds of thing in it. The
playground needs to represent them differently — they are not the same kind
of "element."

### 1a. Registry components — the pickable layer

Five sources, all **shadcn-compatible registries** — same JSON schema, same
install mechanism (`npx shadcn@latest add <registry>/<name>`), same
`components.json` registration pattern. This uniformity is what makes
aggregation feasible at all.

| Registry | Endpoint | Item count (fluctuates — always fetch live) | Owns |
|---|---|---|---|
| Bklit | `https://bklit.com/r/registry.json` | ~56 | Charts, data viz |
| KokonutUI | `https://kokonutui.com/r/registry.json` | ~51 | Layout blocks |
| Sora UI | `https://ui.soralabs.io.vn/r/registry.json` | 69–139, observed to vary week to week | Text/scroll motion effects |
| Componentry | `https://componentry.dev/r/registry.json` | ~55 | Signature one-off polish (reference-first) |
| React Bits | `https://reactbits.dev/r/registry.json` | ~205 unique × 4 variants = ~820 entries | Cursor/micro-interaction candy |

**Confirmed item schema** (fetched live from KokonutUI, structurally
identical across all five registries — this is the shadcn registry spec,
not a per-vendor format):

```json
{
  "name": "ai-prompt",
  "type": "registry:component",
  "title": "AI Input Selector",
  "description": "Animated AI chat input with model selection...",
  "dependencies": ["lucide-react", "motion"],
  "registryDependencies": ["textarea", "button", "dropdown-menu"],
  "files": [
    { "path": "components/kokonutui/ai-prompt.tsx", "type": "registry:component" },
    { "path": "hooks/use-auto-resize-textarea.ts", "type": "registry:hook" }
  ]
}
```

Root-level registry document: `{ "$schema", "name", "homepage", "items": [...] }`.

**No preview images or thumbnails in this schema.** None of the five
registries embed a preview URL in `registry.json` — visual browsing means
either rendering each component's source live (expensive, requires a real
React runtime per item) or linking out to that registry's own hosted docs
site for a preview. Decide this early; it's the single biggest UX-vs-effort
tradeoff in the whole project.

**React Bits' variant quadrupling is a data-modeling problem, not just a
gotcha.** `ClickSpark-JS-CSS` / `-JS-TW` / `-TS-CSS` / `-TS-TW` are the same
conceptual component. The aggregated index should either collapse these to
one logical entry with a variant selector, or the picker will show ~615
duplicate-looking rows for React Bits alone. This project's own scaffold is
always TypeScript + Tailwind, so `-TS-TW` is the only variant worth
surfacing by default.

### 1b. Engines — configured, not picked

Motion, GSAP, Lenis, Vanta are npm packages, not registry items. There is no
`registry.json` to fetch — no list of "things" to browse. They're
**project-wide capabilities**, turned on or off once (by preset), not
selected per-section the way a component is. The playground should not try
to list "GSAP" as a browsable card next to "AI Input Selector" — it's a
different kind of decision (a checkbox per engine, not a search result).

Where these genuinely intersect the pickable layer: Sora UI's items are
*built on* Motion+GSAP, so an aggregated index entry for a Sora UI component
should carry which engine(s) it depends on (visible in its
`dependencies`/`registryDependencies` fields) — that's browsable metadata on
a pickable item, not a separate engine entry.

### 1c. Reference-only sources — not indexable at all

Componentry is *semantically* reference-first even though it's technically
a registry (its own docs frame it as "inspect and customize," not "install
as-is" — see `gotchas.md`). Codrops is a pure reference site with no API, no
registry, nothing to index — it only gets consulted via `WebFetch` at the
point of need for a named technique. Neither belongs in a searchable index
the same way Bklit's chart list does; if Componentry is included, flag it
visually as "reference" so it's not confused with a one-click install.

---

## 2. Unified data model

A normalized element record the playground would actually index and search:

```ts
interface DesignElement {
  id: string;                    // `${source}:${name}` — stable across refreshes
  name: string;                  // registry item `name`
  title: string;                 // registry item `title`
  description: string;
  source: 'bklit' | 'kokonutui' | 'soralabs' | 'componentry' | 'react-bits';
  category: RoutingCategory;     // maps to registry-routing.md's table — computed once at aggregation time, not per-query
  installCommand: string;        // `npx shadcn@latest add ${source}/${name}`
  npmDependencies: string[];     // from registry item's `dependencies`
  registryDependencies: string[];// from registry item's `registryDependencies`
  variant?: {                    // React Bits only
    language: 'JS' | 'TS';
    styling: 'CSS' | 'TW';
  };
  engineDependency?: ('motion' | 'gsap')[]; // inferred from npmDependencies, informational only
  referenceOnly: boolean;        // true for Componentry — surfaced differently in UI
  lastVerified: string;          // ISO date of last successful registry fetch — see §4 on staleness
}

type RoutingCategory =
  | 'charts'
  | 'layout-blocks'
  | 'text-scroll-effects'
  | 'signature-polish'
  | 'micro-interactions';
```

`category` should be assigned per-source, not per-item — every Bklit item is
`charts`, every KokonutUI item is `layout-blocks`, etc. — since
`registry-routing.md` assigns ownership at the *source* level, not the
component level. Don't build a per-item classifier; it doesn't exist upstream
and inventing one is a much bigger (and shakier) project than this spec.

---

## 3. Aggregation strategy

Because all five sources share the shadcn registry schema, the fetch/merge
step is mechanical:

```
for each of the 5 registry.json endpoints:
  fetch, validate against the shared shape
  map each item -> DesignElement (source, category fixed per registry)
  for react-bits: collapse 4 variants into 1 logical entry, default to -TS-TW
merge into one array, write to a single index file
```

**Snapshot vs. live is the central architectural decision**, and it's
downstream of where the playground itself runs (§4):

- **Live fetch** (server-side, e.g. a Next.js app with an API route) —
  always current, no staleness, but requires a runtime that isn't subject to
  browser CSP restrictions.
- **Snapshot** (pre-fetched JSON, refreshed on a schedule) — works anywhere,
  including a CSP-restricted client, but can go stale. Registry item counts
  are already observed to change week-to-week (Sora UI: 139 → 69 between two
  runs of `setup-stack.sh` in the same week) — a stale snapshot showing a
  since-removed component is a broken install command, not just an outdated
  count.

If a snapshot approach is chosen, it needs a refresh mechanism
(`lastVerified` in the schema above) and the UI needs to surface staleness
rather than hide it — showing a component as available when its upstream
registry entry is gone is worse than not indexing it at all.

---

## 4. Where this actually runs

This determines whether "live fetch" is even available, so it should be
decided before any other implementation work.

**Claude Artifacts are CSP-restricted** — an Artifact's sandbox blocks
`fetch`/`XHR`/`WebSocket` to any host outside a short allowlist
(`cdnjs.cloudflare.com`, `cdn.jsdelivr.net`, Tailwind's play-CDN,
`code.jquery.com` for scripts; Google Fonts for stylesheets). **None of the
five registry hosts are on that list**, so an Artifact **cannot live-fetch
`registry.json` from bklit.com, kokonutui.com, ui.soralabs.io.vn,
componentry.dev, or reactbits.dev at runtime.** This directly overturns the
"Artifact prototype first" suggestion floated earlier in this project's
`SKILL.md` — it only works if the aggregated index is pre-built and embedded
as a static asset (via the Artifact's own asset store, or inlined JSON),
never fetched live from inside the page.

Two real options:

1. **Artifact + pre-built static index** — cheapest to stand up, matches the
   original "prototype first" instinct, but is inherently a snapshot (§3);
   refreshing means re-running an aggregation step outside the Artifact
   (e.g. Claude Code fetches the 5 registries, writes the merged JSON,
   re-publishes the Artifact with the updated asset). Fine for validating
   the browse/search/select UX cheaply before committing to more.
2. **A real small app** (Next.js, deployed anywhere with server-side fetch —
   Vercel, or local `next dev` for personal use) — can fetch registries live
   server-side with no CSP constraint, so no staleness problem at all. More
   setup than an Artifact, but removes the entire snapshot/refresh design
   problem in §3.

Given the "prototype cheaply first" instinct in `SKILL.md`'s "Future
direction" note still holds, option 1 is the right *first* build — just with
the CSP constraint now explicit, so the prototype is a static-index Artifact
from the start rather than discovering the CSP block partway through.

---

## 5. Export contract

The one piece of this whole project that actually plugs back into
`web-stack-init`. Whatever the playground's UI looks like, it should end in
writing a small file at the target project's root:

```json
{
  "schema": "design-playground-selection/v1",
  "selections": [
    {
      "id": "soralabs:text-effect",
      "installCommand": "npx shadcn@latest add @soralabs/text-effect",
      "intendedUse": "hero headline reveal"
    }
  ]
}
```

`web-stack-init`'s Phase 2 (`references/design-interview.md`) would read
this file, if present, and skip the component-sourcing question entirely —
treating the export as an already-answered version of that question, one
entry at a time instead of one whole-project bias. That's a small, contained
change to Phase 2's logic. **This file format is worth building before the
picker UI itself** — it's what makes the picker's output actually useful,
independent of how polished the browsing experience is.

---

## 6. Non-goals (for now)

- **No per-component visual preview rendering.** None of the five registries
  provide one; building a live-render sandbox for arbitrary registry
  component source is a project on its own, not a feature of this one.
- **No write access back to the registries.** Read/aggregate/index only.
- **No attempt to index Motion, GSAP, Lenis, Vanta, or Codrops as browsable
  items** — see §1b/§1c. They stay configuration toggles and reference
  links, not search results.
- **No per-component category inference.** Category is assigned per-source
  per `registry-routing.md`, not computed from each item's own content.

---

## 7. Open questions

- Does React Bits' JS/CSS variants ever matter for a use case this stack
  actually has (e.g. a non-Tailwind consumer)? If never, drop them from the
  index entirely rather than modeling a variant system for a case that
  doesn't happen.
- Should Componentry appear in search results at all, given it's
  reference-only? Or does it live in a separate "inspiration" section of the
  UI, structurally distinct from the four installable registries?
- Who refreshes the snapshot (§3), and how often? Manual re-run, a scheduled
  job, or fetched fresh on every playground session open (which reintroduces
  the CSP problem for an Artifact-hosted version)?
