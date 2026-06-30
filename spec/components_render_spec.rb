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

  it 'plots one sparkline point per series entry' do
    html = render('sparkline')
    points = html[/<polyline points="([^"]*)"/, 1].split(/\s+/).reject(&:empty?)
    expect(points.size).to eq(12)
  end

  it 'shows a placeholder instead of crashing on an empty sparkline series' do
    html = renderer.render(catalog.find('sparkline'), size: 'full', data: { 'series' => [] })
    expect(html).to include('No data')
    expect(html).not_to include('Liquid error')
  end

  it 'survives a flat sparkline series without dividing by zero' do
    flat = { 'series' => [{ 'value' => 5 }, { 'value' => 5 }, { 'value' => 5 }], 'unit' => 'W' }
    html = renderer.render(catalog.find('sparkline'), size: 'full', data: flat)
    expect(html).to include('<polyline')
    expect(html).not_to include('Liquid error')
  end

  it 'renders the stat value' do
    expect(render('stat')).to include('1,240')
  end

  it 'omits the stat delta when none is given' do
    html = renderer.render(catalog.find('stat'), size: 'full', data: { 'value' => '5', 'label' => 'Idle' })
    expect(html).not_to include('<svg')
    expect(html).not_to include('Liquid error')
  end

  it 'renders a divider section header from its title' do
    expect(render('divider')).to include('Living room').and include('class="divider"')
  end

  it 'renders a bare divider when no title is given' do
    html = renderer.render(catalog.find('divider'), size: 'full', data: {})
    expect(html).to include('class="divider"')
    expect(html).not_to include('title--small')
  end

  it 'renders the text body with the configured clamp' do
    html = renderer.render(catalog.find('text'), size: 'full', data: { 'body' => 'Hello there' }, options: { 'clamp' => '3' })
    expect(html).to include('Hello there').and include('data-clamp="3"')
  end

  it 'surfaces no Liquid errors in any component render' do
    catalog.components.each do |component|
      html = renderer.render(component, size: component.sizes.first)
      expect(html).not_to include('Liquid error'), "#{component.name} produced a Liquid error"
    end
  end
end
