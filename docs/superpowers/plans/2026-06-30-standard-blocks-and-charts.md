# Standard Blocks + Chart Presets — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add the data-driven standard building blocks (table, list, badge, progress, stat, divider, text) plus a configurable Chartkick/Highcharts chart engine + 10 presets to the `trmnl-homey-components` library.

**Architecture:** Same component convention as existing blocks — `<category>/<name>.{liquid,meta.yml,sample.yml}`, each `.liquid` defines `{% template homey_<name> %}` using **only framework classes** (charts are the sole inline-style exception). Charts use one engine + thin preset wrappers (spec approach A). Storybook gains a `textarea` control type for the raw chart `library:` box.

**Tech Stack:** Liquid (trmnl-liquid 0.7), Sinatra storybook, RSpec, Chartkick 5.0.1 + Highcharts 12.3.0 (CDN).

**Specs:** `docs/superpowers/specs/2026-06-30-standard-blocks-design.md`, `…-chart-presets-design.md`. Markup sketches + data shapes per block live there; this plan is the task/verify roadmap.

**Per-task definition of done:** component files created → `bundle exec rspec` green (incl. the no-Liquid-errors sweep) → focused spec for happy path + main edge case → visually screenshotted in Chrome at the sizes its `meta` declares → committed.

---

## File structure

```
components/
  generic/   stat.{liquid,meta,sample}  divider.{…}  text.{…}    # + existing
  indicators/ badge.{…}  progress.{…}                            # NEW category
  data/      list.{…}  table.{…}                                 # NEW category
  charts/    chart.{…}  line.{…} column.{…} stacked_column.{…}   # NEW category
             area.{…} donut.{…} scatter.{…} combo.{…}
             waterfall.{…} heatmap.{…} pattern_area.{…}
web/public/storybook.js   # add `textarea` control case
spec/components_render_spec.rb  # add focused specs per block
```

---

## Phase 1 — Core blocks

Build order: simplest first to re-validate the pattern, table last (most complex).

### Task 1: `generic/stat`
**Files:** Create `components/generic/stat.{liquid,meta.yml,sample.yml}`; Test: `spec/components_render_spec.rb`.
- [ ] Write `stat.liquid` per spec §5 (item > meta empty + content; `value value--xxlarge value--tnums data-fit-value`; `label`; optional grayscale delta = small SVG triangle + `label`, colored `label--success/error` only when `color_delta` opt-in).
- [ ] `meta.yml`: title/description/sizes `[full, half_vertical, quadrant]`; usage `{% render "homey_stat", value: value, label: label, unit: unit, delta: delta, delta_dir: delta_dir, trmnl: trmnl %}`; options `size` (select), `color_delta` (boolean, default no).
- [ ] `sample.yml`: `value: "1,240"`, `unit: " W"`, `label: Power now`, `delta: "+8%"`, `delta_dir: up`.
- [ ] Spec: renders the value `1,240`; with `delta` omitted, no delta markup / no Liquid error.
- [ ] Run `bundle exec rspec`; screenshot full + quadrant; commit.

### Task 2: `generic/divider`
**Files:** Create `components/generic/divider.{liquid,meta.yml,sample.yml}`.
- [ ] `divider.liquid`: `{% if title %}<span class="group-header" data-group-header="true">{{ title }}</span>{% endif %}<div class="divider"></div>`.
- [ ] `meta.yml`: sizes all; usage `{% render "homey_divider", title: title %}`; no options.
- [ ] `sample.yml`: `title: Living room`.
- [ ] Spec: with title → includes `group-header` + title; without title → only `divider`, no error.
- [ ] rspec; screenshot; commit.

### Task 3: `generic/text`
**Files:** Create `components/generic/text.{liquid,meta.yml,sample.yml}`.
- [ ] `text.liquid` per spec §7: optional `title`; `<div class="richtext"><div class="content content--base" data-clamp="{{ clamp }}">{{ body }}</div></div>`; align class from option.
- [ ] `meta.yml`: options `clamp` (select 2/3/4/6 default 4), `align` (select left/center default left); usage passes `title, body, trmnl`.
- [ ] `sample.yml`: a short status note (3-4 sentences to exercise clamp).
- [ ] Spec: body text appears; clamp attr reflects option.
- [ ] rspec; screenshot; commit.

### Task 4: `indicators/badge`
**Files:** Create `components/indicators/badge.{liquid,meta.yml,sample.yml}`.
- [ ] `badge.liquid` per spec §3: `<div class="flex flex--row gap--small">` looping `badges` → `<span class="label label--{{ b.style | default: default_style }}">{{ b.text }}</span>`.
- [ ] `meta.yml`: options `size` (select), `default_style` (select, default outline); usage passes `badges, trmnl`.
- [ ] `sample.yml`: `badges: [{text: Online, style: filled}, {text: Heating, style: outline}, {text: Window open, style: warning}, {text: Battery low, style: error}]`.
- [ ] Spec: all four texts appear; a badge without `style` falls back to `default_style`; empty `badges` → no error.
- [ ] rspec; screenshot; commit.

### Task 5: `indicators/progress`
**Files:** Create `components/indicators/progress.{liquid,meta.yml,sample.yml}`.
- [ ] **Verify exact DOM** for `progress-bar`/`progress-dots` in `template_guide.md` §9 before writing (prove-it). Then `progress.liquid`: bar → `<div class="progress-bar" data-progress="{{ value }}">…`; dots → `<div class="progress-dots" data-progress="{{ value }}" data-progress-total="{{ total }}">`; with `label` + `value`% caption.
- [ ] `meta.yml`: options `style` (select bar/dots default bar), `size`; usage passes `value, label, total, trmnl`.
- [ ] `sample.yml`: `value: 65`, `label: Battery`, `total: 100`.
- [ ] Spec: `data-progress="65"` present; style=dots switches to `progress-dots`.
- [ ] rspec; screenshot; commit.

### Task 6: `data/list`
**Files:** Create `components/data/list.{liquid,meta.yml,sample.yml}`.
- [ ] **Verify** column-count attribute (`data-overflow-cols` vs `-max-cols`) in `template_guide.md` §11. Then `list.liquid` per spec §2: `columns` container + overflow engine; loop `items` → `item` > `meta` (index when `numbered`, else empty) + `content` (`value value--tnums` + `label`).
- [ ] `meta.yml`: options `columns` (select 1/2/3 default 1), `numbered` (boolean default no); usage passes `items, trmnl`.
- [ ] `sample.yml`: `items:` top energy consumers (name + W), ~8 entries.
- [ ] Spec: all item labels appear; `numbered: yes` shows `index`; empty `items` → "No data", no error.
- [ ] rspec; screenshot 1-col + 2-col; commit.

### Task 7: `data/table`
**Files:** Create `components/data/table.{liquid,meta.yml,sample.yml}`.
- [ ] `table.liquid` per spec §1: `<table class="table table--{{ size }}" {% if limit %}data-table-limit="true"{% endif %}>` with `thead` from `columns`, `tbody` from `rows`; numeric cells `value value--tnums` + right align via `align`.
- [ ] `meta.yml`: options `size` (select default small), `limit` (boolean default yes); usage passes `columns, rows, align, trmnl`.
- [ ] `sample.yml`: device table — `columns: [Device, Power, Status]`, ~10 `rows`, `align: [left, right, left]`.
- [ ] Spec: header + a known cell appear; empty `rows` → empty tbody / "No data", no error; `limit: yes` adds `data-table-limit`.
- [ ] rspec; screenshot full + half_horizontal; commit.

---

## Phase 2 — Chart engine + presets (spec: chart-presets-design)

### Task 8: storybook `textarea` control
**Files:** Modify `web/public/storybook.js`.
- [ ] Add a `case 'textarea'` to the controls builder: render a `<textarea>` bound to the option key, re-render on `input` (debounced like existing controls). Confirm renderer already passes string defaults through (no renderer change per spec).
- [ ] Manually verify in storybook that editing a textarea option re-renders. Commit.

### Task 9: `charts/chart` (the engine)
**Files:** Create `components/charts/chart.{liquid,meta.yml,sample.yml}`.
- [ ] `chart.liquid` per chart spec: read knobs from `cfg`; `chart_id = "homey-chart" | append_random`; emit CDN scripts (+ `highcharts-more`/`pattern-fill` when `modules`); `<script>` builds `data = {{ data | json }}`, `ckOpts` (colors/curve/points/legend/stacked), e-ink `eink` library from knobs, parse raw `library` box in try/catch → `{}`, `deepMerge(eink, raw)`, `new Chartkick[CONSTRUCTOR](chart_id, data, ckOpts)` with `chartkick:load` guard. Inline `deepMerge` helper.
- [ ] `meta.yml`: the 9 controls from spec (chart_type, color_scheme, curve, points, legend, stacked, data_labels, gridlines, modules) + `library` (textarea, default `{}`); usage passes `data, trmnl`.
- [ ] `sample.yml`: a simple 2-series time set.
- [ ] Spec: emits `new Chartkick["LineChart"]` + both CDN tags; `modules` on adds the two module tags; raw `library` content round-trips; `append_random` id is unique per render.
- [ ] rspec; screenshot (real Chartkick renders in Chrome); commit.

### Task 10: presets (thin wrappers)
**Files:** Create 10 folders under `components/charts/`: `line, column, stacked_column, area, donut, scatter, combo, waterfall, heatmap, pattern_area`.
- [ ] Each `.liquid`: `{% template homey_chart_<name> %}{% render "homey_chart", data: data, trmnl: trmnl %}{% endtemplate %}`.
- [ ] Each `.meta.yml`: usage + the preset's default knob values (per chart spec preset table — e.g. stacked_column `stacked: yes`; donut `chart_type: pie` + donut; combo/waterfall/heatmap/pattern_area set a non-empty `library` default).
- [ ] Each `.sample.yml`: data shaped for that type (single series; 2 series for stacked/combo; slices for donut; `[[x,y]]` scatter; `[[x,y,v]]` heatmap; waterfall steps).
- [ ] Spec: each preset's distinguishing trait appears (e.g. `stacked_column` → `stacked`; `waterfall` → `chart.type` waterfall; `pattern_area` → module tags).
- [ ] rspec; screenshot each preset; commit (may batch presets into 2-3 commits).

---

## Extra-helpful touches (house style)

- [ ] Friendly, accurate `description` in every `meta.yml` (shown in the gallery).
- [ ] Realistic Homey-flavored sample data (not lorem).
- [ ] After all blocks: add a short `COMPONENTS.md` to the repo listing every block by category with one-line purpose + usage snippet (the library's quick-reference).
- [ ] Verify the storybook gallery groups the new `data`/`indicators`/`charts` categories cleanly.

---

## Self-review

- **Spec coverage:** standard-blocks §1-7 → Tasks 1-7; chart spec engine/knobs/presets/textarea → Tasks 8-10. Out-of-scope items (map, calendar) correctly absent.
- **Type consistency:** template names `homey_<name>`; usage args match each `.liquid`'s reads; chart presets all `{% render "homey_chart" %}`.
- **Prove-it flags:** progress DOM (§9) and list column attr (§11) explicitly verified before writing — no guessed classes.
