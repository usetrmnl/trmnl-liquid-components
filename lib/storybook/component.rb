# frozen_string_literal: true

require 'yaml'

module Storybook
  # One previewable component: its Liquid {% template %} body plus the sample data
  # and metadata (title/description/sizes/usage) that drive its storybook entry.
  Component = Data.define(:name, :category, :markup, :sample, :meta) do
    def self.from(liquid_path)
      base = liquid_path.sub(/\.liquid\z/, '')
      new(
        name: File.basename(base),
        category: File.basename(File.dirname(liquid_path)),
        markup: File.read(liquid_path),
        sample: YAML.load_file("#{base}.sample.yml") || {},
        meta: YAML.load_file("#{base}.meta.yml") || {}
      )
    end

    def usage = meta.fetch('usage')
    def title = meta.fetch('title', name)
    def description = meta['description']
    def sizes = meta.fetch('sizes', %w[full])

    # Configurable controls (Storybook "args"): each {key, type, label, default, choices}.
    # Their values are injected as trmnl.plugin_settings.custom_fields_values.<key>.
    def options = meta.fetch('options', [])
  end
end
