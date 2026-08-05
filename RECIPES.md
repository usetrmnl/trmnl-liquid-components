# Recipes

Ready-to-paste screens built from the components. Each one reads a Homey
snapshot through a **Plugin Merge** reference, so it works on any account once
the installer picks their own Homey plugin.

| Recipe | Shows |
|---|---|
| [`home_overview.liquid`](recipes/home_overview.liquid) | Average temperature, humidity and total power, over a compact device readout |
| [`energy.liquid`](recipes/energy.liquid) | Total power, top consumer, per-zone chart |
| [`climate.liquid`](recipes/climate.liquid) | Average temperature and humidity, with a per-sensor breakdown |
| [`home_status.liquid`](recipes/home_status.liquid) | Devices on, active alarms as chips, all-clear line when nothing is wrong |
| [`zones.liquid`](recipes/zones.liquid) | The first two zones with every device in them |

## How the binding works

A recipe cannot hardcode a plugin id — the author's id means nothing on someone
else's account. Instead it declares a `plugin_instance_select` field, and TRMNL
aliases whatever the installer picked under that field's keyname:

```ruby
# app/models/user.rb
locals_hash[keyname] = locals_hash[selected]
```

So a field named `homey` makes `homey.merge_variables` resolve to the
installer's own Homey data. Every recipe here reads exactly that, and a spec
fails if one ever hardcodes `private_plugin_<id>`.

## Trying one without a Homey

The snapshot is just JSON, so you do not need the hardware to exercise a recipe.
Create the source plugin, then push the captured sample at it:

    bin/push-snapshot <plugin-uuid>            # private plugin, webhook strategy
    bin/push-snapshot <plugin-uuid> --native   # native homey plugin

It posts `web/seeds/data.json` — a real capture from a Homey Pro — and prints
the response. Pass `--file` to send your own.

## Setting one up

1. **Get Homey data into TRMNL.** Create a private plugin with strategy
   **Webhook**, then point the companion app's `push_url` at
   `https://trmnl.com/api/custom_plugins/<uuid>` so it posts
   `{merge_variables: {...snapshot}}`. Hide it in your playlist — it is a data
   source, not a screen.
2. **Create the recipe plugin.** New private plugin, strategy **Plugin Merge**.
3. **Add the picker.** One custom field, `field_type: plugin_instance_select`,
   `keyname: homey`. This is what installers use to choose their own source.
4. **Paste the markup.** `rake 'build:shared[energy,climate,home_status,zone_section]'`
   into the plugin's shared markup, then a file from `recipes/` into the view.
5. **Publish.** Forkers pick their Homey in step 3's field and the recipe
   renders their home.

Hiding the source is safe here: a webhook plugin re-arms itself when data
arrives, so it does not need the background refresh that hidden *polling*
sources depend on.
