# trmnl-homey-components

Open-source Liquid component library for rendering [Homey](https://homey.app)
smart-home data on [TRMNL](https://trmnl.com) e-ink screens, plus a storybook to
preview components with editable sample data and copy their markup.

The components are plain TRMNL `{% template %}` blocks — paste them into a
private plugin's **shared markup** and `{% render %}` them against your Homey
data. Two tiers:

- **Generic** (`cap_tile`, `device_card`, `zone_section`) — render any device by
  its capabilities.
- **Heroes** (`energy`, `weather`, `solar`, `climate_home`) — curated layouts for
  the highest-value use cases.

Plus generic blocks (`stat`, `sparkline`, `badge`, `progress`, `list`, `table`,
…) and a configurable chart engine with ten presets. See
[COMPONENTS.md](COMPONENTS.md) for the full catalog, usage, and chart recipes.

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
