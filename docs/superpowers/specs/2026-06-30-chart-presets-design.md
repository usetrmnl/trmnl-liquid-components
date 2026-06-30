# Chart Presets + Live Tuning — Design

**Date:** 2026-06-30
**Repo:** `trmnl-homey-components`
**Status:** Approved (approach A)

## Goal

Give people a gallery of good-looking, e-ink-tuned chart presets that each render correctly out of the box AND can be tuned live in the storybook (controls + copy-the-markup). Built on Chartkick 5.0.1 + Highcharts 12.3.0 — the exact versions TRMNL serves.

## Why this shape

A TRMNL chart is a **screenshot**, so interactivity (tooltip/hover/zoom/animation) is dead weight. "Interesting configuration" therefore means **structure & ink**: chart type, curve vs straight, fill vs line, gridline texture, data-label density, patterned fills. That is a small, curate-able surface — not Highcharts' full ~3000-option API.

Reading the source confirmed the merge model (`chartkick.src.js:113-156`, `jsOptionsFunc`): Chartkick starts from its defaults, applies simple knobs (`colors`, `stacked`, `curve`, `points`, `legend`, `min`/`max`), then deep-merges `opts.library` **last**. Our two-tier config maps directly onto that: easy knobs → top-level Chartkick opts; Highcharts styling + raw box → `library:`.

## Architecture (approach A): one engine + thin preset wrappers

- **`charts/chart.liquid`** — the engine. Defines `{% template homey_chart %}`. Holds ALL logic: reads knobs, emits CDN scripts (+ modules), builds the e-ink `library`, deep-merges the raw box, renders the Chartkick constructor. Shown in the gallery as "Custom chart" (the fully-open one).
- **Presets** — each is a folder with three small files:
  - `.liquid` — a ~3-line wrapper: `{% template homey_chart_<name> %}{% render "homey_chart", data: data, trmnl: trmnl %}{% endtemplate %}`
  - `.meta.yml` — `usage` + the preset's **default knob values** (this is what gives the preset its identity)
  - `.sample.yml` — `data` shaped for that chart type
- **`generic/sparkline`** (existing) stays as the one zero-JS option.

Adding a chart later = one folder, three small files. E-ink defaults live in exactly one place (the engine).

### Preset list (rich set, v1)

| Preset | Constructor | Identity comes from (meta defaults) |
|---|---|---|
| `line` | `LineChart` | curve off, points off |
| `column` | `ColumnChart` | — |
| `stacked_column` | `ColumnChart` | `stacked: yes` + 2-series sample |
| `area` | `AreaChart` | curve on |
| `donut` | `PieChart` | `donut: yes` + slice sample |
| `scatter` | `ScatterChart` | `[[x,y]]` sample |
| `combo` (dual-axis) | `LineChart` | library default `{series:[{type:'column',yAxis:0},{type:'line',yAxis:1}],yAxis:[{},{opposite:true}]}` + 2-series sample |
| `waterfall` | `ColumnChart` | library default `{chart:{type:'waterfall'},series:[{type:'waterfall'}]}` |
| `heatmap` | `ScatterChart` | library default `{chart:{type:'heatmap'}}` + `[[x,y,value]]` sample |
| `pattern_area` | `AreaChart` | modules on + library default with a `pattern-fill` series fill |

The non-native flavors (combo, waterfall, heatmap, pattern_area) get their identity from a **non-empty default in the raw library box**, so the engine stays generic — it just renders `new Chartkick[constructor](id, data, opts)` where `opts.library` may carry a `chart.type`/`series` override. A power user editing the box sees that default and can tweak it.

## Config knobs (engine controls)

| Control | Type | Maps to |
|---|---|---|
| `chart_type` | select: line/column/area/pie/scatter | Chartkick constructor |
| `color_scheme` | select: black / grey / black+grey | Chartkick `colors` (`['#000']` / `['#888']` / `['#000','#888']`) |
| `curve` | boolean | Chartkick `curve` (line/area) |
| `points` | boolean | Chartkick `points` |
| `legend` | select: none/bottom/right | Chartkick `legend` |
| `stacked` | boolean | Chartkick `stacked` |
| `data_labels` | boolean | library `plotOptions.series.dataLabels.enabled` |
| `gridlines` | select: solid/dotted/none | library axis `gridLineDashStyle` + `gridLineWidth` |
| `modules` | boolean | when on, engine also emits `highcharts-more.js` + `modules/pattern-fill.js` (default off; `pattern_area` defaults it on) |
| `library` | **textarea** | raw Highcharts JSON, deep-merged over the curated library |

## E-ink default library (baked into the engine, always applied unless overridden)

```js
{ chart: { backgroundColor: "transparent", style: { fontFamily: "inherit" } },
  plotOptions: { series: { animation: false, borderWidth: 0 } },
  credits: { enabled: false },
  tooltip: { enabled: false },
  yAxis: { gridLineColor: "#000", title: { text: null }, labels: { style: { color: "#000", fontSize: "14px" } } },
  xAxis: { lineColor: "#000", labels: { style: { color: "#000", fontSize: "14px" } } } }
```

Colors default `["#000000", "#888888"]`. Curated knobs adjust parts of this; the raw box overrides anything.

## Data flow

1. Preset wrapper passes `data` + `trmnl` into `homey_chart` (`{% render %}` is isolated scope — both must be passed).
2. Engine reads knobs from `trmnl.plugin_settings.custom_fields_values`; the storybook renderer has already injected the preset's meta defaults + any live overrides there.
3. Engine emits `highcharts.js` + `chartkick.min.js` from `trmnl.com/js/...`, plus `highcharts-more.js` + `modules/pattern-fill.js` when the `modules` knob is on.
4. Container `<div id="{{ chart_id }}">` with `chart_id = "homey-chart" | append_random` (unique-id fix from earlier).
5. `<script>` builds:
   ```js
   var data = {{ data | json }};
   var ckOpts = { colors: ..., curve: ..., points: ..., legend: ..., stacked: ... };
   var eink = { ...curated library from knobs... };
   var rawStr = {{ cfg.library | default: '{}' | json }};
   var raw = {}; try { raw = JSON.parse(rawStr); } catch (e) {}
   ckOpts.library = deepMerge(eink, raw);      // ~6-line deep merge; raw wins
   var make = function () { new Chartkick[CONSTRUCTOR]("{{ chart_id }}", data, ckOpts); };
   if ("Chartkick" in window) { make(); } else { window.addEventListener("chartkick:load", make, true); }
   ```

`{{ data | json }}` uses the trmnl-liquid `json` filter (`filters.rb`). `deepMerge` is a small inline helper (objects merge recursively; arrays/scalars replaced).

## Storybook addition

One new control type — `textarea` — for the raw library box:
- `web/public/storybook.js`: add a `textarea` case to the controls builder (render a `<textarea>`, read `.value`, trigger re-render on input).
- Renderer `option_defaults` already reads `option['default']` as a string, so a multi-line JSON default flows through unchanged. No renderer change needed.
- The POST `/c/:name/:size/render` endpoint already forwards `{data, options}` — unchanged.

## Error handling / edge cases

- **Invalid raw JSON** → `JSON.parse` in `try/catch`, falls back to `{}` (curated library still applies). Chart never breaks from a typo in the box.
- **Empty `data`** → Chartkick renders an empty chart frame (its own "No data" handling); no crash.
- **Duplicate charts on one screen** → unique `append_random` container id (verified pattern).
- **Module not loaded but library needs it** (e.g. user types a bubble series without modules on) → Highcharts logs an error in console and skips; the page still renders. Documented, not guarded (power-user box).

## Testing

- **Focused specs** (assert generated markup, since charts are JS-rendered):
  - `line` preset emits `new Chartkick["LineChart"]` + both CDN tags.
  - `pattern_area` includes `highcharts-more` + `pattern-fill` script tags.
  - raw library box content appears in the generated script (round-trips through the engine).
  - container id is unique per render (`append_random`).
  - `combo` sample serializes to two named series in the `data` JSON.
  - existing no-Liquid-errors sweep covers every new component.
- **Visual:** real Chrome (chrome-devtools-mcp) actually runs Chartkick over the network, so each preset is eyeballed rendering for real at 800×480.

## LOC budget

Engine ~130 · 10 presets × ~15 ≈ 150 · storybook.js textarea ~15 · specs ~70 ≈ **~365 LOC**. Flag if any preset pushes over.

## Out of scope (YAGNI)

- GeoChart / maps, BubbleChart (low value for Homey, more modules).
- Binding presets to real Homey Insights history (that's Project A's `Snapshot#to_merge_variables`).
- PNG/e-ink dithering export, color beyond black/grey.
- A visual drag-config GUI — the controls panel + raw box are enough.
