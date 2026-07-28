# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'json'
require_relative 'renderer'

module Storybook
  # Renders the catalog to static files so any static host can serve the gallery.
  # Every component/variant/size combination becomes its own HTML file; the index
  # is a picker that swaps the preview iframe between them.
  class Site
    WEB = File.expand_path('../../web', __dir__)

    def self.slug(name) = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')

    def initialize(catalog) = (@catalog = catalog)

    def build(root)
      FileUtils.rm_rf(root)
      FileUtils.mkdir_p(root)
      FileUtils.cp(Dir.glob(File.join(WEB, 'public', '*.{css,js}')), root)
      pages = @catalog.components.flat_map { |component| write_previews(root, component) }
      File.write(File.join(root, 'index.html'), index_html)
      pages
    end

    private

    def write_previews(root, component)
      renderer = Renderer.new(@catalog)
      component.variants.flat_map do |variant|
        component.sizes.flat_map do |size|
          Framework::DEVICES.keys.map do |device|
            path = File.join(root, 'c', component.name, self.class.slug(variant['name']), device, "#{size}.html")
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, renderer.render(component, size:, args: variant['args'] || {}, device:))
            path
          end
        end
      end
    end

    # Everything the picker needs, so the page needs no server to browse.
    def catalog_json
      @catalog.by_category.transform_values do |components|
        components.map do |component|
          {
            name: component.name, title: component.title, description: component.description,
            sizes: component.sizes, bundle: @catalog.bundle_for(component), usage: component.usage,
            variants: component.variants.map { { name: it['name'], slug: self.class.slug(it['name']) } }
          }
        end
      end.to_json
    end

    def index_html
      catalog = catalog_json
      devices = Framework::DEVICES.map { |name, spec| { name:, label: spec[:label] } }.to_json
      ERB.new(File.read(File.join(WEB, 'views', 'site.erb'))).result(binding)
    end
  end
end
