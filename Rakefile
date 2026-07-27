# frozen_string_literal: true

require_relative 'lib/storybook/catalog'
require_relative 'lib/storybook/docs'
require_relative 'lib/storybook/site'

def catalog = @catalog ||= Storybook::Catalog.load(File.expand_path('components', __dir__))

namespace :build do
  desc 'Regenerate shared.liquid; name components to write only those and what they need'
  task :shared, [:names] do |_task, args|
    names = args.to_a.flat_map { it.split(',') }.map(&:strip).reject(&:empty?)
    wanted = names.map { catalog.find(it) or abort("unknown component: #{it}") }
    markup = wanted.empty? ? catalog.shared_markup : catalog.bundle_for_all(wanted)
    File.write(File.expand_path('shared.liquid', __dir__), "#{markup}\n")
    puts "Wrote shared.liquid (#{markup.scan(/\{%\s*template /).size} templates)"
  end

  desc 'Render the gallery to _site/ as static files (no server needed)'
  task :site do
    root = File.expand_path('_site', __dir__)
    pages = Storybook::Site.new(catalog).build(root)
    docs = Storybook::Docs.new(catalog).build(root)
    puts "Wrote #{root} (#{pages.size} previews, #{docs.size} markdown pages, llms.txt)"
  end
end
