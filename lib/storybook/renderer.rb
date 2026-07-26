# frozen_string_literal: true

require 'trmnl/liquid'
require_relative '../framework'

module Storybook
  # Renders one component via trmnl-liquid: the catalog's templates are prepended
  # as shared scope, then the component's `usage` {% render %} call is appended and
  # evaluated against the (sample or edited) data. A fresh environment per render
  # keeps each component's registered templates isolated.
  class Renderer
    def initialize(catalog) = @catalog = catalog

    def render(component, size:, data: component.sample, options: {}, markup: nil)
      context = context_for(component, data, options)
      body = render_liquid("#{scope_for(component, markup)}\n#{component.usage}", context)
      # Fragment components (tiles/cards) declare `wrap: true` so previews frame
      # them in a layout the way a host plugin would; screen-level components
      # (heroes, zone_section) emit their own layout + title_bar.
      body = %(<div class="layout layout--col gap">\n#{body}\n</div>) if component.meta['wrap']
      Framework.wrap(body, size:)
    end

    # Mirrors a real private plugin: data as top-level vars, every template in scope.
    def render_markup(markup, size:, data: {})
      context = stringify(data).merge('trmnl' => { 'plugin_settings' => { 'instance_name' => 'Preview' } })
      Framework.wrap(render_liquid("#{@catalog.shared_markup}\n#{markup}", context), size:)
    end

    private

    # Shared template scope, with this component's markup swapped for the live
    # editor's version when one is supplied (other components stay intact so
    # dependencies like cap_tile/homey_chart still resolve). Blank = use on-disk.
    def scope_for(component, markup)
      return @catalog.shared_markup if markup.nil? || markup.strip.empty?

      @catalog.components.map { |c| c.name == component.name ? markup : c.markup }.join("\n")
    end

    # Merge option defaults with any overrides and expose them exactly where a
    # real TRMNL plugin reads its settings, so a component is drop-in compatible.
    def context_for(component, data, options)
      values = option_defaults(component).merge(stringify(options))
      stringify(data).merge(
        'trmnl' => { 'plugin_settings' => { 'instance_name' => 'Sample', 'custom_fields_values' => values } }
      )
    end

    def option_defaults(component)
      component.options.to_h { |option| [option['key'].to_s, option['default'].to_s] }
    end

    def render_liquid(markup, context)
      environment = TRMNL::Liquid.new
      ::Liquid::Template.parse(markup, environment:).render(context)
    rescue StandardError => e
      "Liquid error: #{e.message}"
    end

    def stringify(object)
      case object
      when Hash then object.to_h { |key, value| [key.to_s, stringify(value)] }
      when Array then object.map { stringify(it) }
      else object
      end
    end
  end
end
