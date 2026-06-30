# Component reference

A cheat-sheet for every component in the library. For setup, Docker, and the
`shared.liquid` master, see the [README](README.md).

## How to use one

1. Run `rake build:shared` and paste `shared.liquid` into your private plugin's
   **shared markup** (it defines every `{% template %}`).
2. `{% render %}` the component you want in a view, passing your Homey data.
3. Options (the `opts` column below) are read from
   `trmnl.plugin_settings.custom_fields_values`, i.e. your plugin's custom
   fields. The storybook lets you tune them live and shows the values to copy.

Data is the merge-variables contract — it comes from your source plugin. Each
component's `*.sample.yml` is the exact shape it expects.

## Generic — render any device

| Component | Shows | Usage | Options |
|---|---|---|---|
| `cap_tile` | One capability (label + value + unit) | `{% render "homey_cap_tile", label: label, value: value, unit: unit %}` | — |
| `device_card` | A device + all its capabilities | `{% render "homey_device_card", device: device %}` | — |
| `zone_section` | Device cards grouped under a zone | `{% render "homey_zone_section", zone: zone %}` | — |

## Heroes — curated layouts

| Component | Shows | Usage | Options |
|---|---|---|---|
| `energy` | Live power, per-zone split, top consumer | `{% render "homey_energy", energy: energy, trmnl: trmnl %}` | `show_chart`, `chart_type` |
| `weather` | Indoor/outdoor temp, humidity, wind, rain | `{% render "homey_weather", weather: weather, trmnl: trmnl %}` | `columns` |
| `solar` | Production now, today, grid feed-in | `{% render "homey_solar", solar: solar %}` | — |
| `climate_home` | Avg + per-room temp, devices-on, alarms | `{% render "homey_climate_home", climate: climate, home: home %}` | — |

## Generic blocks — compose your own screen

Blocks with options take `trmnl: trmnl` so the engine can read your custom
fields — drop it and the options fall back to their defaults.

| Component | Shows | Usage | Options |
|---|---|---|---|
| `stat` | One hero metric + optional up/down delta | `{% render "homey_stat", value: value, label: label, unit: unit, delta: delta, delta_dir: delta_dir, trmnl: trmnl %}` | `size`, `color_delta` |
| `sparkline` | Zero-JS SVG trend line (most reliable) | `{% render "homey_sparkline", series: series, unit: unit, trmnl: trmnl %}` | `fill`, `show_dots` |
| `divider` | Separator, optional section header | `{% render "homey_divider", title: title %}` | — |
| `text` | Prose block with line-clamp | `{% render "homey_text", title: title, body: body, trmnl: trmnl %}` | `clamp`, `align` |
| `badge` | Row of status badges | `{% render "homey_badge", badges: badges, trmnl: trmnl %}` | `size`, `default_style` |
| `progress` | Bar or dots toward a target | `{% render "homey_progress", value: value, label: label, total: total, trmnl: trmnl %}` | `style`, `size` |
| `list` | Label/value rows (top-N, leaderboard) | `{% render "homey_list", items: items, trmnl: trmnl %}` | `columns`, `numbered` |
| `table` | Rows with framework overflow ("and N more") | `{% render "homey_table", columns: columns, rows: rows, trmnl: trmnl %}` | `size`, `limit` |

**`sparkline` vs the chart engine:** the sparkline is pure SVG — no chart
library, no async CDN load. On a flaky e-ink refresh it's the safest trend
chart. Reach for the chart engine when you need bars, pies, axes, or legends.

## Charts

One engine, `homey_chart`, plus ten presets that pre-fill it. The engine pulls
Chartkick + Highcharts from `trmnl.com` and applies an e-ink theme (transparent
background, dotted black gridlines, no tooltip/animation/credits).

| Preset | Style | Usage |
|---|---|---|
| `homey_chart` | Fully configurable (all knobs + raw library) | `{% render "homey_chart", data: data, trmnl: trmnl %}` |
| `line` | Time-series line | `{% render "homey_chart_line", data: data, trmnl: trmnl %}` |
| `column` | Vertical bars | `{% render "homey_chart_column", ... %}` |
| `bar` | Horizontal bars (good for long labels) | `{% render "homey_chart_bar", ... %}` |
| `area` | Filled, smoothed line | `{% render "homey_chart_area", ... %}` |
| `stacked_column` | Two series stacked | `{% render "homey_chart_stacked_column", ... %}` |
| `scatter` | X/Y points | `{% render "homey_chart_scatter", ... %}` |
| `donut` | Proportions as a ring | `{% render "homey_chart_donut", ... %}` |
| `combo` | Column + line together | `{% render "homey_chart_combo", ... %}` |
| `waterfall` | Running total of +/- steps | `{% render "homey_chart_waterfall", ... %}` |
| `pattern_area` | Diagonal-hatch fill | `{% render "homey_chart_pattern_area", ... %}` |

### Engine options

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
