# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'storybook/catalog'
require 'storybook/site'

RSpec.describe Storybook::Site do
  subject(:site) { described_class.new(catalog) }

  let(:catalog) { Storybook::Catalog.load(File.join(ROOT, 'components')) }

  around do |example|
    Dir.mktmpdir { |dir| example.run(@root = dir) }
  end

  attr_reader :root

  it 'writes one page per component, variant, size and device' do
    expected = catalog.components.sum { |c| c.variants.size * c.sizes.size } * Storybook::Framework::DEVICES.size
    expect(site.build(root).size).to eq(expected)
  end

  it 'renders each variant with its own arguments' do
    site.build(root)
    expect(File.read(File.join(root, 'c/stat/mega/og/full.html'))).to include('value--mega')
    expect(File.read(File.join(root, 'c/stat/default/og/full.html'))).to include('value--xxlarge')
  end

  it 'gives each device its own screen class, which is what activates responsive utilities' do
    site.build(root)
    expect(File.read(File.join(root, 'c/stat/default/og/full.html'))).to include('screen--md')
    expect(File.read(File.join(root, 'c/stat/default/x/full.html'))).to include('screen--lg')
  end

  it 'writes an index that carries the catalog and needs no server' do
    site.build(root)
    index = File.read(File.join(root, 'index.html'))
    expect(index).to include('window.CATALOG').and include('Stat / KPI')
    expect(index).not_to include('fetch(')
  end

  it 'copies the stylesheet and scripts alongside the pages' do
    site.build(root)
    expect(File.exist?(File.join(root, 'storybook.css'))).to be(true)
    expect(File.exist?(File.join(root, 'site.js'))).to be(true)
  end

  it "escapes closing tags in embedded markup, which a component's own <script> would end early" do
    site.build(root)
    expect(File.read(File.join(root, 'index.html'))).not_to include('</script></script>')
  end

  it 'slugs variant names into directory-safe segments' do
    expect(described_class.slug('Two column, numbered')).to eq('two-column-numbered')
  end

  it 'clears stale pages from a previous build' do
    FileUtils.mkdir_p(File.join(root, 'c', 'gone'))
    File.write(File.join(root, 'c', 'gone', 'full.html'), 'stale')
    site.build(root)
    expect(File.exist?(File.join(root, 'c', 'gone', 'full.html'))).to be(false)
  end
end
