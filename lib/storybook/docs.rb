# frozen_string_literal: true

require 'fileutils'

module Storybook
  # Writes the catalog as markdown next to the gallery, following the llms.txt
  # convention: an index for discovery, one page per component, and a single
  # concatenated file an agent can read in one fetch.
  class Docs
    SUMMARY = 'Liquid components for TRMNL e-ink screens. Paste shared.liquid into a private ' \
              "plugin's shared markup, then {% render %} a component. Options are render " \
              'arguments, not plugin custom fields.'

    def initialize(catalog) = (@catalog = catalog)

    def build(root)
      pages = @catalog.components.map do |component|
        path = File.join(root, 'c', "#{component.name}.md")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, page(component))
        path
      end
      File.write(File.join(root, 'llms.txt'), index)
      File.write(File.join(root, 'llms-full.txt'), full)
      pages
    end

    private

    def index
      sections = @catalog.by_category.map do |category, components|
        links = components.map { "- [#{it.title}](c/#{it.name}.md): #{it.description}" }
        "## #{category.capitalize}\n\n#{links.join("\n")}"
      end
      "# TRMNL components\n\n> #{SUMMARY}\n\n#{sections.join("\n\n")}\n"
    end

    def full
      "# TRMNL components\n\n> #{SUMMARY}\n\n#{@catalog.components.map { page(it) }.join("\n---\n\n")}"
    end

    def page(component)
      <<~MARKDOWN
        # #{component.title}

        #{component.description}

        - Template: `#{component.template}`
        - Sizes: #{component.sizes.join(', ')}

        ## Usage

        ```liquid
        #{component.usage}
        ```
        #{variants(component)}
        ## Sample data

        ```yaml
        #{component.sample.to_yaml.delete_prefix("---\n").strip}
        ```

        ## Markup

        ```liquid
        #{component.markup.strip}
        ```
      MARKDOWN
    end

    def variants(component)
      named = component.variants.reject { (it['args'] || {}).empty? }
      return '' if named.empty?

      lines = named.map { "- **#{it['name']}** — #{it['args'].map { |k, v| "#{k}: \"#{v}\"" }.join(', ')}" }
      "\n## Variants\n\n#{lines.join("\n")}\n"
    end
  end
end
