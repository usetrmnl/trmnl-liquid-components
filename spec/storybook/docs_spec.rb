# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'storybook/catalog'
require 'storybook/docs'

RSpec.describe Storybook::Docs do
  subject(:docs) { described_class.new(catalog) }

  let(:catalog) { Storybook::Catalog.load(File.join(ROOT, 'components')) }

  around do |example|
    Dir.mktmpdir { |dir| example.run(@root = dir) }
  end

  attr_reader :root

  it 'writes one markdown page per component' do
    expect(docs.build(root).size).to eq(catalog.components.size)
  end

  it 'gives a component page its template, usage, sample data and markup' do
    docs.build(root)
    page = File.read(File.join(root, 'c/stat.md'))
    expect(page).to include('`trmnl_stat`')
    expect(page).to include('{% render "trmnl_stat"')
    expect(page).to include('Power now')
    expect(page).to include('{% template trmnl_stat %}')
  end

  it 'lists a component\'s named variants with their arguments' do
    docs.build(root)
    expect(File.read(File.join(root, 'c/stat.md'))).to include('**Mega**').and include('size: "mega"')
  end

  it 'omits the variants section when a component has only defaults' do
    docs.build(root)
    expect(File.read(File.join(root, 'c/solar.md'))).not_to include('## Variants')
  end

  it 'indexes every component under its category in llms.txt' do
    docs.build(root)
    index = File.read(File.join(root, 'llms.txt'))
    expect(index).to include('## Blocks').and include('## Homey')
    catalog.components.each { expect(index).to include("(c/#{it.name}.md)") }
  end

  it 'inlines every component in llms-full.txt so one fetch is enough' do
    docs.build(root)
    full = File.read(File.join(root, 'llms-full.txt'))
    expect(full).to include('{% template trmnl_stat %}').and include('{% template homey_energy %}')
  end
end
