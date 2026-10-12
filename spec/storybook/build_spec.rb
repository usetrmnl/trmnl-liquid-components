# frozen_string_literal: true

require 'spec_helper'
require 'storybook/catalog'

RSpec.describe 'shared.liquid build' do
  it 'contains every component template' do
    catalog = Storybook::Catalog.load(File.join(ROOT, 'components'))
    shared = catalog.shared_markup
    expect(shared).to include('homey_cap_tile').and include('homey_energy').and include('homey_climate').and include('homey_home_status').and include('homey_insights')
  end

  it 'matches the committed shared.liquid, so a component change also rebuilds it' do
    catalog = Storybook::Catalog.load(File.join(ROOT, 'components'))
    expect(File.read(File.join(ROOT, 'shared.liquid'))).to eq("#{catalog.shared_markup}\n")
  end
end
