# Component reference

A cheat-sheet for every component in the library. For setup, Docker, and the
`shared.liquid` master, see the [README](README.md).

## How to use one

1. Paste the component's **shared markup** into your plugin's shared markup. The
   gallery shows exactly what to copy — the component plus every template it
   renders. Copying the template alone is not enough for the chart presets or
   anything built on `homey_cap_tile`: Liquid renders an unknown `{% render %}`
   as blank, so the content silently disappears.
2. Paste the `{% render %}` call into a view, passing your data.
3. Options are `{% render %}` arguments — pass them inline, per instance. Two
   `trmnl_stat`s on one screen can use different sizes. Omit an argument and the
   component falls back to its own default. No plugin custom fields required.

Data is the merge-variables contract — it comes from your source plugin. Each
component's `*.sample.yml` is the exact shape it expects, and each
`*.meta.yml` lists the named variants the storybook renders.

`trmnl_*` components are generic and work with any data source. `homey_*`
components read the Homey snapshot shape.

## Blocks — compose your own screen

| Component | Shows | Usage | Arguments |
|---|---|---|---|
| `stat` | One hero metric + optional up/down delta | `{% render "trmnl_stat", value: value, label: label, unit: unit, delta: delta, delta_dir: delta_dir %}` | `size`, `color_delta` |
| `sparkline` | Zero-JS SVG trend line (most reliable) | `{% render "trmnl_sparkline", series: series, title: title, unit: unit %}` | `fill`, `show_dots` |
| `divider` | Separator, optional section header | `{% render "trmnl_divider", title: title %}` | — |
| `text` | Prose block with line-clamp | `{% render "trmnl_text", title: title, body: body %}` | `clamp`, `align` |
| `badge` | Row of status badges | `{% render "trmnl_badge", badges: badges %}` | `size`, `default_style` |
| `progress` | Bar or dots toward a target | `{% render "trmnl_progress", value: value, label: label, total: total %}` | `style`, `size` |
| `list` | Label/value rows (top-N, leaderboard) | `{% render "trmnl_list", items: items %}` | `columns`, `numbered` |
| `table` | Rows with framework overflow ("and N more") | `{% render "trmnl_table", columns: columns, rows: rows, align: align %}` | `size`, `limit` |

## Homey — render any device

These take the companion app's snapshot **as it arrives** — a flat `devices`
list plus `zone_names` — and aggregate while rendering. That is the same wire
format `Plugins::Homey::Snapshot` consumes server-side, so both ingestion paths
feed the same components with no translation layer. Liquid cannot build an
array, so there is no adapter to write and none to keep in step: each component
sums, groups and ranks where it draws.

| Component | Shows | Usage | Arguments |
|---|---|---|---|
| `cap_tile` | One capability (label + value + unit) | `{% render "homey_cap_tile", label: label, value: value, unit: unit %}` | — |
| `device_card` | One device, from its flat snapshot fields | `{% render "homey_device_card", device: device %}` | — |
| `zone_section` | Every device in one zone | `{% render "homey_zone_section", devices: devices, zone: zone %}` | — |
| `energy` | Total power, per-zone split, top consumer | `{% render "homey_energy", devices: devices %}` | `show_chart`, `chart_type` |
| `climate` | Temperature hero (single-sensor aware) + humidity + sensor cards | `{% render "homey_climate", devices: devices %}` | — |
| `home_status` | Devices on, lights on, alarm chips / all-clear | `{% render "homey_home_status", devices: devices %}` | — |
| `insights` | Latest reading, 24h range, line chart from the insight series | `{% render "homey_insights", series: insight_series, title: insight_title, unit: insight_unit %}` | — |
| `weather` | Sample data only — see note below | `{% render "homey_weather", weather: weather %}` | `columns` |
| `solar` | Sample data only — see note below | `{% render "homey_solar", solar: solar %}` | — |

**`weather` and `solar` have no producer.** The snapshot carries eight fields per
device — name, zone, class, power, temperature, humidity, on, alarms — with no
indoor/outdoor split, no wind, rain or pressure, and no cumulative energy. Solar
kWh totals are not derivable from instantaneous watts at all. Both components
render their sample data and wait for the companion push to widen.

**`sparkline` vs the chart engine:** the sparkline is pure SVG — no chart
library, no async CDN load. On a flaky e-ink refresh it's the safest trend
chart. Reach for the chart engine when you need bars, pies, axes, or legends.

## Charts

One engine, `trmnl_chart`, plus ten presets that pre-fill it. Each preset is a
one-line wrapper whose `{% render %}` arguments *are* the recipe, so pasting one
needs no configuration. The engine pulls Chartkick + Highcharts from `trmnl.com`
and applies an e-ink theme (transparent background, dotted black gridlines, no
tooltip/animation/credits).

| Preset | Style | Usage |
|---|---|---|
| `trmnl_chart` | Fully configurable (all knobs + raw library) | `{% render "trmnl_chart", data: data %}` |
| `line` | Time-series line | `{% render "trmnl_chart_line", data: data %}` |
| `column` | Vertical bars | `{% render "trmnl_chart_column", ... %}` |
| `bar` | Horizontal bars (good for long labels) | `{% render "trmnl_chart_bar", ... %}` |
| `area` | Filled, smoothed line | `{% render "trmnl_chart_area", ... %}` |
| `stacked_column` | Two series stacked | `{% render "trmnl_chart_stacked_column", ... %}` |
| `scatter` | X/Y points | `{% render "trmnl_chart_scatter", ... %}` |
| `donut` | Proportions as a ring | `{% render "trmnl_chart_donut", ... %}` |
| `combo` | Column + line together | `{% render "trmnl_chart_combo", ... %}` |
| `waterfall` | Running total of +/- steps | `{% render "trmnl_chart_waterfall", ... %}` |
| `pattern_area` | Diagonal-hatch fill | `{% render "trmnl_chart_pattern_area", ... %}` |

### Engine arguments

`chart_type` (line/column/bar/area/pie/scatter), `color_scheme`
(black/grey/black+grey), `curve`, `points`, `legend` (none/bottom/right),
`stacked`, `data_labels`, `gridlines` (dotted/solid/none), `modules` (load
`highcharts-more` + `pattern-fill`), and `library` — a raw Highcharts JSON
object deep-merged last, your escape hatch for anything the knobs don't cover.

### Recipes (what the presets actually set)

Chartkick's Highcharts adapter has quirks; these are where the advanced presets
put their config so it survives.

- **Combo** — set `type` on each **data series**, not in the library. Chartkick
  overwrites `library.series`, but keeps keys on the data:
  ```json
  { "data": [ { "name": "Grid", "type": "column", "data": [...] },
              { "name": "Solar", "type": "spline", "data": [...] } ] }
  ```
  Keep `chart_type: line` — the column constructor rebuilds series and drops the
  per-series type.
- **Donut** — `library`: `{"plotOptions":{"pie":{"innerSize":"60%"}},"colors":["#000000","#606060","#a0a0a0","#d0d0d0"]}`.
  The grey ramp matters: one colour makes every slice dither to the same texture.
- **Stacked** — use `color_scheme: black+grey` so the two segments stay legible.
- **Waterfall** — `modules: yes` and `library`: `{"chart":{"type":"waterfall"}}`,
  with `chart_type: line` (only the line constructor honours a library chart type).
- **Pattern area** — `modules: yes` and a `library` `plotOptions.series.fillColor`
  pattern. Hatching reads better than solid black once dithered.
- **Heatmap is not available** — `trmnl.com` serves no heatmap module.

### E-ink chart rules

Black on transparent; dotted gridlines; no tooltips. Pies and stacks need
distinct **grey shades** (or patterns), never colour. Keep series to 2–3 — e-ink
can't separate more. For a simple trend, prefer `sparkline` over the engine.
