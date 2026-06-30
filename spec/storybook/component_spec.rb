# frozen_string_literal: true

require 'spec_helper'
require 'storybook/component'
require 'tmpdir'
require 'fileutils'

RSpec.describe Storybook::Component do
  subject(:component) { described_class.from(File.join(dir, 'generic', 'demo.liquid')) }

  let(:dir) { Dir.mktmpdir }

  before do
    FileUtils.mkdir_p(File.join(dir, 'generic'))
    File.write(File.join(dir, 'generic', 'demo.liquid'), '{% template homey_demo %}hi{% endtemplate %}')
    File.write(File.join(dir, 'generic', 'demo.sample.yml'), "label: Power\n")
    File.write(File.join(dir, 'generic', 'demo.meta.yml'),
               "title: Demo\nusage: '{% render \"homey_demo\" %}'\nsizes: [full]\n")
  end

  it 'reads its name from the filename' do
    expect(component.name).to eq('demo')
  end

  it 'reads its category from the parent directory' do
    expect(component.category).to eq('generic')
  end

  it 'loads sample data' do
    expect(component.sample).to eq('label' => 'Power')
  end

  it 'exposes the usage snippet from meta' do
    expect(component.usage).to eq('{% render "homey_demo" %}')
  end
end
