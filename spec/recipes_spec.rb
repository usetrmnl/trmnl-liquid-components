# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'trmnl/liquid'
require 'storybook/catalog'

# Recipes are view markup a user pastes into a private plugin using the
# plugin_merge strategy. TRMNL aliases the selected instance under the
# plugin_instance_select field's keyname, which is why `homey` resolves.
RSpec.describe 'recipes' do
  let(:catalog) { Storybook::Catalog.load(File.join(ROOT, 'components')) }
  let(:snapshot) { JSON.parse(File.read(File.join(ROOT, 'web/seeds/data.json'))) }

  # What user.merged_plugin_locals hands a plugin_merge template: every instance keyed by "<keyname>_<id>", plus the field-name alias the recipe reads.
  def merged(payload)
    locals = { 'merge_variables' => payload }
    { 'private_plugin_134064' => locals, 'homey' => locals }
  end

  def render(recipe, data)
    markup = File.read(File.join(ROOT, 'recipes', "#{recipe}.liquid"))
    Liquid::Template.parse("#{catalog.shared_markup}\n#{markup}", environment: TRMNL::Liquid.new).render(data)
  end

  Dir.glob(File.join(File.expand_path('..', __dir__), 'recipes', '*.liquid')).sort.each do |path|
    recipe = File.basename(path, '.liquid')

    it "renders #{recipe} from a merged Homey payload" do
      html = render(recipe, merged(snapshot))
      expect(html).not_to include('Liquid error')
      expect(html).to include('title_bar')
      expect(html).not_to include('Waiting for the first push')
    end

    it "shows #{recipe}'s not-connected state before the first push" do
      html = render(recipe, merged({}))
      expect(html).to include('Waiting for the first push')
      expect(html).not_to include('Liquid error')
    end

    it "never hardcodes #{recipe} to the author's plugin id, which a fork would resolve through the alias and render blank" do
      expect(File.read(path)).not_to match(/private_plugin_\d+/)
    end
  end

  it 'renders real device data through the energy recipe' do
    expect(render('energy', merged(snapshot))).to include('1840').and include('Sample Kettle Plug')
  end

  it 'groups devices by zone in the zones recipe' do
    expect(render('zones', merged(snapshot))).to include('Lounge').and include('Kitchen')
  end

  # An unknown {% render %} produces BLANK output, never an error — so every
  # template a recipe references must resolve to a catalog component.
  it 'resolves every template a recipe renders to a catalog component' do
    Dir.glob(File.join(ROOT, 'recipes', '*.liquid')).sort.each do |path|
      File.read(path).scan(/\{%\s*render\s+"(\w+)"/).flatten.uniq.each do |template|
        expect(catalog.by_template(template)).not_to be_nil, "#{File.basename(path)} renders unknown template #{template}"
      end
    end
  end
end
