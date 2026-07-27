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

## Regenerate the copy-paste master

    bundle exec rake build:shared   # writes shared.liquid (all components)
