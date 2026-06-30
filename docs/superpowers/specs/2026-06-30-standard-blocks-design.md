# Standard Building Blocks — Design

**Date:** 2026-06-30
**Repo:** `trmnl-homey-components`
**Status:** Approved (build set = "everything useful")

## Goal

Add the standard UI building blocks that real TRMNL recipes use but our library lacks, so people composing Homey screens have a covering set. Blocks are ranked and chosen from a data-driven cross-correlation, not guesswork.

## Evidence (979 markup-bearing recipes, public API)

Building-block usage measured across the public recipe corpus (`trmnl.com/recipes.json` + per-recipe archive ZIPs):

| Block | Usage | Status |
|---|---|---|
| `value--` big number | 38% | have (cap_tile/heroes) → also add standalone `stat` |
| `item` meta+content | 34% | have (cap_tile) |
| description/text | 27% | **add `text`** |
| `columns` list | 24% | **add `list`** |
| SVG chart | 23% | have (sparkline) |
| badge `label--*` | 22% | **add `badge`** |
| table | 16% | **add `table`** |
| JS chart | 8.5% | spec'd separately (chart presets) |
| divider | 11% | **add `divider`/section-header** |
| progress | 4% | **add `progress`** (distinctive, cheap) |
| map/geo | 1% | skip |
| `item--meta-emphasis` (calendar) | 0% | skip — documented but unused |

Key learnings driving the design: SVG charts outnumber JS charts ~3:1 (sparkline-first was right); 67% of recipes use inline `style=` because the framework lacks a block they need — so **our blocks stay pure framework-class (no inline styles)** as a quality differentiator (charts are the only inline-style exception, since chart libs require it).

## Architecture

Same proven convention as existing components — each block is `<category>/<name>.{liquid,meta.yml,sample.yml}`:
- `.liquid` defines `{% template homey_<name> %}…{% endtemplate %}` using **only framework classes**.
- `.meta.yml` — `title`, `description`, `sizes`, `usage` (the `{% render %}` call), optional `options` (controls).
- `.sample.yml` — data shaped like the contract, Homey-flavored.

New gallery categories: `data/` (table, list), `indicators/` (badge, progress). `stat`, `text`, `divider` go in `generic/`. Existing folders unchanged.

v3 color note: colored variants (`label--success/error/...`) only show color on color devices; the framework is grayscale-first. So every block **defaults to grayscale-safe** markup (`label--outline`/`--filled`, `text--gray-N`) and exposes color as an opt-in option.

## Blocks

### 1. `data/table` (16%)
- **Purpose:** structured rows with the framework Table-Overflow engine.
- **Data:** `columns: [String]` (headers), `rows: [[cell,…]]`, optional `align: [left|right]` per column.
- **Markup:** `<table class="table table--{size}" data-table-limit="true"><thead><tr><th><span class="title title--small">…</th></tr></thead><tbody><tr><td><span class="label">…</span></td>…</tr></tbody></table>`; numeric columns get `value value--tnums` + right align.
- **Options:** `size` (select: xsmall/small/base/large, default small), `limit` (boolean, default yes → `data-table-limit`).
- **Sample:** device list — Device / Power / Status rows.

### 2. `data/list` (24%)
- **Purpose:** auto-balanced list of label/value rows (top-N, key stats, leaderboard).
- **Data:** `items: [{label, value, unit}]`.
- **Markup:** a `columns` container using the overflow engine for column count — `<div class="columns" data-overflow="true" data-overflow-cols="{n}">` — containing repeated `item` → `meta` (index when numbered, else empty) + `content` (`value value--tnums` + `label`). *Exact column-count attribute (`data-overflow-cols` vs `data-overflow-max-cols`) verified against `template_guide.md` §11 at build time.*
- **Options:** `columns` (select 1/2/3, default 1), `numbered` (boolean, default no → index in meta).
- **Sample:** top energy consumers (name + W).

### 3. `indicators/badge` (22%)
- **Purpose:** a row of status badges (device states, alarms).
- **Data:** `badges: [{text, style}]`, `style ∈ outline|filled|inverted|primary|success|error|warning|gray`.
- **Markup:** `<div class="flex flex--row gap--small">` of `<span class="label label--{style}">{text}</span>`.
- **Options:** `size` (select small/base/large), `default_style` (select, fallback when a badge omits style; default outline).
- **Sample:** Online / Heating / Window open / Battery low.

### 4. `indicators/progress` (4%)
- **Purpose:** progress toward a target (battery %, capacity, goal).
- **Data:** `value` (0–100), `label`, optional `total` (for dots).
- **Markup:** bar → `<div class="progress-bar" data-progress="{value}">`; dots → `<div class="progress-dots" data-progress="{value}" data-progress-total="{total}">`; with a `label` + `value` caption row. *Exact DOM verified against `template_guide.md` §9 at build time.*
- **Options:** `style` (select bar/dots, default bar), `size`.
- **Sample:** Battery 65%.

### 5. `generic/stat` (38% use `value--`)
- **Purpose:** one hero metric — giant number + label + optional delta.
- **Data:** `value`, `label`, `unit`, optional `delta` (e.g. "+12%"), `delta_dir` (up|down).
- **Markup:** `<div class="item"><div class="meta"></div><div class="content"><span class="value value--xxlarge value--tnums" data-fit-value="true">{value}{unit}</span><span class="label">{label}</span></div></div>`; delta as a grayscale-safe indicator (SVG triangle + `label`; colored `label--success/error` when color opt-in is on). **No emoji** (renders as boxes on e-ink) — verified visually at build.
- **Options:** `size` (value size select), `color_delta` (boolean, default no → grayscale delta).
- **Sample:** 1,240 W · Power now · +8%.

### 6. `generic/divider` (11%)
- **Purpose:** section separators + section headers.
- **Data:** optional `title`.
- **Markup:** `<div class="divider"></div>`; with title → `<span class="group-header" data-group-header="true">{title}</span>` above a `divider`.
- **Options:** none (trivial).
- **Sample:** "Living room" header + line.

### 7. `generic/text` (27%)
- **Purpose:** prose / description block with overflow control.
- **Data:** optional `title`, `body`.
- **Markup:** optional `title` + `<div class="richtext"><div class="content content--base">{body}</div></div>` with `data-clamp="{lines}"`.
- **Options:** `clamp` (select 2/3/4/6 lines, default 4), `align` (select left/center, default left).
- **Sample:** a short status note.

## Error handling / edge cases

- **Empty collection** (`rows`/`items`/`badges` empty) → block renders an empty frame or a "No data" `label`, never crashes (matches sparkline guard).
- **Missing optional fields** (`unit`, `delta`, `total`, `title`) → omitted via `{% if %}`; no stray separators/units.
- **Overflow** → handled by the framework engines (`data-table-limit`, `data-overflow`, `data-clamp`) rather than manual truncation.
- **No inline styles** in any block (charts excepted, separate spec).

## Testing

- One focused spec per block: happy path (key sample value appears) + its main edge case (empty collection / missing optional field).
- The existing no-Liquid-errors sweep auto-covers every new component.
- **Visual:** each block screenshotted in Chrome at the sizes its `meta` declares; verify framework styling renders, no emoji boxes, deltas/badges legible on grayscale.

## LOC budget

table ~45 · list ~35 · badge ~22 · progress ~30 · stat ~35 · divider ~12 · text ~22 ≈ **~200 LOC** + meta/sample (~70) + specs (~90) ≈ **~360 LOC**. (Charts are a separate ~365-LOC spec.) Flag if any block pushes over.

## Out of scope (YAGNI)

- map/geo block (1% usage, heavy modules).
- calendar `item--meta-emphasis` (0% usage).
- Reorganizing existing component folders (additive only).
- Binding blocks to live Homey data (Project A concern).
