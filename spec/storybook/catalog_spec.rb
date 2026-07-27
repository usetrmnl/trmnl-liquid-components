# frozen_string_literal: true

require 'spec_helper'
require 'storybook/catalog'
require 'tmpdir'
require 'fileutils'

RSpec.describe Storybook::Catalog do
  subject(:catalog) { described_class.load(dir) }

  let(:dir) { Dir.mktmpdir }

  before do
    FileUtils.mkdir_p(File.join(dir, 'generic'))
    %w[a b].each do |n|
      File.write(File.join(dir, 'generic', "#{n}.liquid"), "{% template homey_#{n} %}#{n}{% endtemplate %}")
      File.write(File.join(dir, 'generic', "#{n}.sample.yml"), "{}\n")
      File.write(File.join(dir, 'generic', "#{n}.meta.yml"), "usage: x\n")
    end
  end

  it 'discovers every component' do
    expect(catalog.components.map(&:name)).to contain_exactly('a', 'b')
  end

  it 'finds a component by name' do
    expect(catalog.find('a').name).to eq('a')
  end

  it 'concatenates all template bodies into one shared scope' do
    expect(catalog.shared_markup).to include('homey_a').and include('homey_b')
  end

  context 'when one component renders another' do
    before do
      File.write(File.join(dir, 'generic', 'a.liquid'),
                 '{% template homey_a %}{% render "homey_b" %}{% endtemplate %}')
    end

    it 'reads the rendered templates as dependencies' do
      expect(catalog.find('a').dependencies).to eq(['homey_b'])
    end

    it 'bundles a dependency in with its dependent' do
      expect(catalog.bundle_for(catalog.find('a'))).to include('homey_a').and include('homey_b')
    end

    it 'leaves an unrelated component out of the bundle' do
      expect(catalog.bundle_for(catalog.find('b'))).not_to include('homey_a')
    end

    it 'defines a shared dependency once across several components' do
      bundle = catalog.bundle_for_all(catalog.components)
      expect(bundle.scan('{% template homey_b %}').size).to eq(1)
    end
  end

  context 'when components render each other in a cycle' do
    before do
      File.write(File.join(dir, 'generic', 'a.liquid'),
                 '{% template homey_a %}{% render "homey_b" %}{% endtemplate %}')
      File.write(File.join(dir, 'generic', 'b.liquid'),
                 '{% template homey_b %}{% render "homey_a" %}{% endtemplate %}')
    end

    it 'resolves without recursing forever' do
      expect(catalog.bundle_for(catalog.find('a'))).to include('homey_a').and include('homey_b')
    end
  end
end
