# trmnl-homey-components

Open-source Liquid component library for rendering [Homey](https://homey.app)
smart-home data on [TRMNL](https://trmnl.com) e-ink screens, plus a storybook to
preview components with editable sample data and copy their markup.

The components are plain TRMNL `{% template %}` blocks — paste them into a
private plugin's **shared markup** and `{% render %}` them against your data.
Options are render arguments, so every instance is configured independently and
nothing depends on plugin custom fields.

- **`trmnl_*` blocks** (`stat`, `sparkline`, `badge`, `progress`, `list`,
  `table`, `text`, `divider`) — generic, any data source.
- **`trmnl_chart`** — a configurable chart engine plus ten one-line presets.
- **`homey_*`** — Homey-shaped: `cap_tile`, `device_card`, `zone_section`, and
  the curated `energy`, `weather`, `solar`, `climate_home` screens.

See [COMPONENTS.md](COMPONENTS.md) for the full catalog, usage, and chart
recipes.

## Run with Docker (Mac / Windows / Linux)

The easiest way — no Ruby needed, one command:

    docker compose up

Then open http://localhost:9292. Component files under `components/` and the UI
under `web/` are mounted into the container, so editing them shows up on refresh
(no rebuild). Stop with `Ctrl-C` (or `docker compose down`).

## Run with Ruby (local)

    bundle install
    bundle exec rackup        # storybook at http://localhost:9292

## Test

    bundle exec rspec

## Build the static gallery

    bundle exec rake build:site     # writes _site/

`_site/` is plain HTML — every component, variant and size is rendered to its
own file at build time, and the index is a picker that swaps between them. It
needs no Ruby at request time, so any static host will serve it:

    cd _site && python3 -m http.server

The same build writes the library as markdown for coding agents, following the
[llms.txt](https://llmstxt.org) convention:

| File | For |
|---|---|
| `llms.txt` | Index — every component, one line each, linked |
| `llms-full.txt` | Every component inline (~31KB), so one fetch is enough |
| `c/<name>.md` | One component: template, usage, variants, sample data, markup |

## Regenerate the copy-paste master

    bundle exec rake build:shared   # writes shared.liquid (all components)

## Contributing

1. Add `components/<category>/<name>.{liquid,meta.yml,sample.yml}`. The
   `.liquid` defines one `{% template %}`; `.meta.yml` carries the title,
   sizes, copy-paste `usage`, and any named `variants`; `.sample.yml` is the
   data the preview renders against.
2. `docker compose up` and check it at every size it declares.
3. `bundle exec rspec` — the suite renders every variant of every component.
4. Open a pull request. CI builds the site and deploys a preview.

Pull requests from forks build but do not deploy: GitHub withholds repository
secrets from forked workflows, so there is no preview URL for them. Push a
branch to this repository to get one.
