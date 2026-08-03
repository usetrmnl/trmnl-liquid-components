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

  desc 'Build paste-ready recipe kits (shared + view markup) into dist/recipes/'
  task :recipes do
    require 'fileutils'
    root = File.expand_path('dist/recipes', __dir__)
    FileUtils.rm_rf(root)
    Dir[File.expand_path('recipes/*.liquid', __dir__)].sort.each do |path|
      name = File.basename(path, '.liquid')
      view = File.read(path)
      wanted = view.scan(/\{%\s*render\s+"(\w+)"/).flatten.uniq.filter_map { catalog.by_template(it) }
      kit = File.join(root, name)
      FileUtils.mkdir_p(kit)
      File.write(File.join(kit, 'shared.liquid'), "#{catalog.bundle_for_all(wanted)}\n")
      File.write(File.join(kit, 'view.liquid'), view)
      puts "dist/recipes/#{name}: view + #{wanted.size} root components (deps resolved)"
    end
  end

  desc 'Render the gallery to _site/ as static files (no server needed)'
  task :site do
    root = File.expand_path('_site', __dir__)
    pages = Storybook::Site.new(catalog).build(root)
    docs = Storybook::Docs.new(catalog).build(root)
    puts "Wrote #{root} (#{pages.size} previews, #{docs.size} markdown pages, llms.txt)"
  end
end
