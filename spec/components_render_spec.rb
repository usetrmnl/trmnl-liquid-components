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
    html = renderer.render(catalog.find('text'), size: 'full', data: { 'body' => 'Hello there' }, args: { 'clamp' => '3' })
    expect(html).to include('Hello there').and include('data-clamp="3"')
  end

  it 'renders all badges with their styles' do
    html = render('badge')
    expect(html).to include('Online').and include('label--warning').and include('label--error')
  end

  it 'falls back to the default style for a badge with no style' do
    html = renderer.render(catalog.find('badge'), size: 'full', data: { 'badges' => [{ 'text' => 'Idle' }] }, args: { 'default_style' => 'filled' })
    expect(html).to include('label--filled').and include('Idle')
  end

  it 'renders a progress bar filled to its value' do
    expect(render('progress')).to include('progress-bar').and include('width: 65%')
  end

  it 'switches progress to dots when configured' do
    html = renderer.render(catalog.find('progress'), size: 'full', data: { 'value' => 3, 'label' => 'Steps', 'total' => 5 }, args: { 'style' => 'dots' })
    expect(html).to include('progress-dots').and include('dot--filled')
  end

  it 'renders the list items' do
    expect(render('list')).to include('Oven').and include('Heat pump')
  end

  it 'numbers the list when configured' do
    html = renderer.render(catalog.find('list'), size: 'full', data: { 'items' => [{ 'label' => 'Solar', 'value' => '1' }] }, args: { 'numbered' => 'yes' })
    expect(html).to include('1.').and include('Solar')
  end

  it 'shows a placeholder for an empty list' do
    html = renderer.render(catalog.find('list'), size: 'full', data: { 'items' => [] })
    expect(html).to include('No data')
    expect(html).not_to include('Liquid error')
  end

  it 'renders the table header and a cell' do
    html = render('table')
    expect(html).to include('Device').and include('Oven')
    expect(html).to include('>On<') # YAML must not coerce On/Off to booleans
  end

  it 'survives an empty table without error' do
    html = renderer.render(catalog.find('table'), size: 'full', data: { 'columns' => ['A'], 'rows' => [] })
    expect(html).not_to include('Liquid error')
  end

  it 'renders a Chartkick chart with the CDN scripts' do
    html = renderer.render(catalog.find('chart'), size: 'full')
    expect(html).to include('Chartkick["LineChart"]').and include('highcharts/12.3.0/highcharts.js').and include('chartkick.min.js')
  end

  it 'switches the chart constructor with chart_type' do
    html = renderer.render(catalog.find('chart'), size: 'full', args: { 'chart_type' => 'column' })
    expect(html).to include('Chartkick["ColumnChart"]')
  end

  it 'loads the extra modules only when enabled' do
    off = renderer.render(catalog.find('chart'), size: 'full')
    on  = renderer.render(catalog.find('chart'), size: 'full', args: { 'modules' => 'yes' })
    expect(off).not_to include('pattern-fill.js')
    expect(on).to include('highcharts-more.js').and include('pattern-fill.js')
  end

  it 'round-trips the raw library box into the chart options' do
    html = renderer.render(catalog.find('chart'), size: 'full', args: { 'library' => '{"chart":{"type":"waterfall"}}' })
    expect(html).to include('waterfall')
  end

  it 'gives each chart a unique container id' do
    a = renderer.render(catalog.find('chart'), size: 'full')[/id="(homey-chart\w+)"/, 1]
    b = renderer.render(catalog.find('chart'), size: 'full')[/id="(homey-chart\w+)"/, 1]
    expect(a).not_to eq(b)
  end

  it 'renders an edited markup override instead of the on-disk template' do
    edited = '{% template trmnl_divider %}<div class="edited-marker"></div>{% endtemplate %}'
    html = renderer.render(catalog.find('divider'), size: 'full', markup: edited)
    expect(html).to include('edited-marker')
  end

  it 'falls back to the on-disk markup when the override is blank' do
    html = renderer.render(catalog.find('divider'), size: 'full', data: { 'title' => 'Living room' }, markup: '   ')
    expect(html).to include('Living room')
  end

  # Each preset is a thin wrapper whose defining config lives in its meta/sample;
  # this proves that config actually reaches the engine output (the adapter quirks
  # that make combo/waterfall/donut work are easy to regress in the meta).
  {
    'bar' => 'Chartkick["BarChart"]',
    'combo' => '"type":"spline"',          # per-series type rides on the data, not library.series
    'donut' => 'innerSize',                # ring hole via raw library
    'stacked_column' => '#888888',         # grey second series so the stack is legible
    'waterfall' => 'highcharts-more.js',   # waterfall series type lives in the more module
    'pattern_area' => 'pattern-fill.js'    # dithered fill needs the pattern module
  }.each do |preset, marker|
    it "carries the #{preset} preset's defining config into the engine output" do
      expect(render(preset)).to include(marker)
    end
  end

  it 'renders every declared variant of every component without a Liquid error' do
    catalog.components.each do |component|
      component.variants.each do |variant|
        html = renderer.render(component, size: component.sizes.first, args: variant['args'] || {})
        expect(html).not_to include('Liquid error'), "#{component.name}/#{variant['name']} produced a Liquid error"
      end
    end
  end

  it 'reads no option from the plugin custom fields, which every instance would share' do
    offenders = catalog.components.select { it.markup.include?('custom_fields_values') }
    expect(offenders.map(&:name)).to be_empty
  end

  it 'gives two instances of one component independent argument values' do
    base = renderer.render(catalog.find('stat'), size: 'full', data: { 'value' => '5' })
    mega = renderer.render(catalog.find('stat'), size: 'full', data: { 'value' => '5' }, args: { 'size' => 'mega' })
    expect(base).to include('value--xxlarge')
    expect(mega).to include('value--mega')
  end
end
