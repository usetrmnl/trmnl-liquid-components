# frozen_string_literal: true

require_relative 'lib/storybook/catalog'
require_relative 'lib/storybook/site'

def catalog = Storybook::Catalog.load(File.expand_path('components', __dir__))

namespace :build do
  desc 'Regenerate shared.liquid (the copy-paste master of all components)'
  task :shared do
    File.write(File.expand_path('shared.liquid', __dir__), "#{catalog.shared_markup}\n")
    puts "Wrote shared.liquid (#{catalog.components.size} components)"
  end

  desc 'Render the gallery to _site/ as static files (no server needed)'
  task :site do
    root = File.expand_path('_site', __dir__)
    pages = Storybook::Site.new(catalog).build(root)
    puts "Wrote #{root} (#{pages.size} previews, #{catalog.components.size} components)"
  end
end
