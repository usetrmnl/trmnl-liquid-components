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

    def render(component, size:, data: component.sample)
      markup = "#{@catalog.shared_markup}\n#{component.usage}"
      Framework.wrap(render_liquid(markup, data), size:)
    end

    private

    def render_liquid(markup, data)
      environment = TRMNL::Liquid.new
      ::Liquid::Template.parse(markup, environment:).render(stringify(data))
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
