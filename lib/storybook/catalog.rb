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
    def by_category = components.group_by(&:category)
    def shared_markup = components.map(&:markup).join("\n")
  end
end
