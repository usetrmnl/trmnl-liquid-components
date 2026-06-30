# frozen_string_literal: true

require 'spec_helper'
require 'storybook/catalog'
require 'storybook/renderer'

RSpec.describe 'components render' do
  let(:catalog) { Storybook::Catalog.load(File.join(ROOT, 'components')) }
  let(:renderer) { Storybook::Renderer.new(catalog) }

  def render(name)
    component = catalog.find(name)
    component.sizes.map { |size| renderer.render(component, size:) }.join
  end

  it 'renders cap_tile with its sample value' do
    expect(render('cap_tile')).to include('1,240')
  end

  it 'renders device_card with each capability value' do
    expect(render('device_card')).to include('5').and include('Yes')
  end

  it 'renders zone_section with the zone name' do
    expect(render('zone_section')).to include('Living room')
  end

  it 'renders the energy hero with total power and top consumer' do
    expect(render('energy')).to include('1,240').and include('Oven')
  end

  it 'renders the weather hero with outdoor temperature' do
    expect(render('weather')).to include('12.4')
  end

  it 'renders the solar hero with production now' do
    expect(render('solar')).to include('820')
  end

  it 'renders the climate_home hero with devices-on count and a room' do
    expect(render('climate_home')).to include('7').and include('Bedroom')
  end

  it 'surfaces no Liquid errors in any component render' do
    catalog.components.each do |component|
      html = renderer.render(component, size: component.sizes.first)
      expect(html).not_to include('Liquid error'), "#{component.name} produced a Liquid error"
    end
  end
end
