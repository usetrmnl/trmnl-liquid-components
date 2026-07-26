# frozen_string_literal: true

require 'spec_helper'
require 'storybook/catalog'
require 'storybook/renderer'
require 'tmpdir'
require 'fileutils'

RSpec.describe Storybook::Renderer do
  subject(:renderer) { described_class.new(catalog) }

  let(:catalog) { Storybook::Catalog.load(dir) }
  let(:dir) { Dir.mktmpdir }
  let(:component) { catalog.find('tile') }

  before do
    FileUtils.mkdir_p(File.join(dir, 'generic'))
    File.write(File.join(dir, 'generic', 'tile.liquid'),
               '{% template homey_tile %}<span>{{ value }}</span>{% endtemplate %}')
    File.write(File.join(dir, 'generic', 'tile.sample.yml'), "value: \"42\"\n")
    File.write(File.join(dir, 'generic', 'tile.meta.yml'),
               "usage: '{% render \"homey_tile\", value: value %}'\nsizes: [full]\n")
  end

  it 'renders the component with its sample data inside the framework frame' do
    html = renderer.render(component, size: 'full')
    expect(html).to include('<span>42</span>').and include('view view--full')
  end

  it 'renders with overridden data' do
    html = renderer.render(component, size: 'full', data: { 'value' => '99' })
    expect(html).to include('<span>99</span>')
  end

  describe '#render_markup (preview playground)' do
    it 'renders arbitrary top-level markup against data, framed like a plugin' do
      html = renderer.render_markup('<b>{{ greeting }}</b>', size: 'full', data: { 'greeting' => 'hi' })
      expect(html).to include('<b>hi</b>').and include('view view--full')
    end

    it 'exposes the registered component templates to the pasted markup' do
      html = renderer.render_markup('{% render "homey_tile", value: "77" %}', size: 'quadrant', data: {})
      expect(html).to include('<span>77</span>')
    end
  end
end
