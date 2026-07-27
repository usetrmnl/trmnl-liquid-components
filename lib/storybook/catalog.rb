# frozen_string_literal: true

require_relative 'component'

module Storybook
  # Discovers components on disk (components/<category>/<name>.liquid) and exposes
  # the combined template scope every render needs (so device_card can call cap_tile).
  class Catalog
    def self.load(root)
      paths = Dir.glob(File.join(root, '*', '*.liquid')).sort
      new(paths.map { |path| Component.from(path) })
    end

    def initialize(components) = @components = components

    attr_reader :components

    def find(name) = components.find { it.name == name }
    def by_template(template) = components.find { it.template == template }
    def by_category = components.group_by(&:category)
    def shared_markup(subset = components) = subset.map(&:markup).join("\n")

    # Everything a component needs in shared markup: itself plus every template it
    # renders, transitively. Paste less and content silently vanishes — Liquid
    # renders an unknown {% render %} as blank rather than raising.
    def bundle_for(component) = bundle_for_all([component])
    def bundle_for_all(wanted) = shared_markup(wanted.each_with_object([]) { |c, found| collect(c, found) })

    private

    def collect(component, found)
      return found if found.include?(component)

      found << component
      component.dependencies.filter_map { by_template(it) }.each { collect(it, found) }
      found
    end
  end
end
