# frozen_string_literal: true

require_relative 'lib/storybook/catalog'

namespace :build do
  desc 'Regenerate shared.liquid (the copy-paste master of all components)'
  task :shared do
    catalog = Storybook::Catalog.load(File.expand_path('components', __dir__))
    File.write(File.expand_path('shared.liquid', __dir__), "#{catalog.shared_markup}\n")
    puts "Wrote shared.liquid (#{catalog.components.size} components)"
  end
end
