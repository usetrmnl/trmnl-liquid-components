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
end
