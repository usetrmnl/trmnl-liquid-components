# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'storybook/catalog'
require 'storybook/renderer'

WIRE_FIELDS = %w[name zone klass available power temperature humidity wind energy titles on alarms capabilities].sort.freeze

RSpec.describe 'components render' do
  let(:catalog) { Storybook::Catalog.load(File.join(ROOT, 'components')) }
  let(:renderer) { Storybook::Renderer.new(catalog) }

  def render(name)
    component = catalog.find(name)
    component.sizes.map { |size| renderer.render(component, size:) }.join
  end

  # Normalizes scope-size noise: chart ids' random suffix and each template's blank line.
  def render_scope(scope, component)
    html = Liquid::Template.parse("#{scope}\n#{component.usage}", environment: TRMNL::Liquid.new)
                           .render(component.sample)
    html.gsub(/(chart)[0-9a-f]{4}/, '\1').gsub(/\s+/, ' ').strip
  end

  # data-clamp truncates by rewriting the element's text, which drops any <img> inside it —
  # the glyph vanishes with no error, and only a screenshot shows it.
  it 'never renders a glyph inside a data-clamp element, which would silently drop it' do
    offenders = Dir[File.join(ROOT, 'components', '**', '*.liquid')].select do |path|
      File.read(path).scan(%r{<span[^>]*data-clamp[^>]*>(.*?)</span>}m).flatten.any? { it.include?('homey_glyph') }
    end
    expect(offenders).to be_empty
  end

  it 'renders cap_tile with its sample value' do
    expect(render('cap_tile')).to include('1,240')
  end

  it 'renders device_card from the capability bag the snapshot carries' do
    expect(render('device_card')).to include('21.5').and include('48').and include('Living room climate')
  end

  it 'tiles a capability the wire shape does not name at all' do
    expect(render('device_card')).to include('measure-co2.svg')
  end

  it 'caps the tiles a device draws and says how many it held back' do
    expect(render('device_card')).to include('more')
  end

  it 'falls back to the flat fields for a producer that sends no capability bag' do
    device = catalog.find('device_card').sample['device'].reject { |key, _| key == 'capabilities' }
    html = renderer.render(catalog.find('device_card'), size: 'full', data: { 'device' => device })
    expect(html).to include('21.5').and include('48')
  end

  it 'draws no glyph on the fallback path, which has no icon to name' do
    device = catalog.find('device_card').sample['device'].reject { |key, _| key == 'capabilities' }
    html = renderer.render(catalog.find('device_card'), size: 'full', data: { 'device' => device })
    expect(html).not_to include('capabilities/')
  end

  it 'shows the battery on a single-sensor climate panel, which is the common home' do
    solo = catalog.find('climate').sample['devices'].select { it['capabilities']['measure_temperature'] }.first(1)
    html = renderer.render(catalog.find('climate'), size: 'full', data: { 'devices' => solo })
    expect(html).to include('capabilities/measure-battery.svg')
  end

  it "draws a raised alarm with Athom's active variant of its glyph" do
    expect(render('home_status')).to include('capabilities/alarm-smoke-active.svg')
  end

  it 'shows the battery of a sensor that reports one, which the flat fields never carried' do
    expect(render('climate')).to include('capabilities/measure-battery.svg')
  end

  it 'renders the glyph a capability names' do
    expect(render('cap_tile')).to include('/images/plugins/homey/capabilities/measure-power.svg')
  end

  it 'omits the glyph when a caller passes no icon' do
    html = renderer.render(catalog.find('cap_tile'), size: 'full',
                           data: { 'label' => 'Power', 'value' => '9', 'unit' => 'W' })
    expect(html).not_to include('<img')
  end

  it 'prefers the device\'s own localized capability title over the English fallback' do
    weather = catalog.find('weather').sample['devices'].find { it['name'] == 'Weather station' }
    html = renderer.render(catalog.find('device_card'), size: 'full', data: { 'device' => weather })
    expect(html).to include('Temperatuur').and include('Windsnelheid')
    expect(html).not_to include('>Temperature<')
  end

  it 'renders zone_section with only the devices in that zone' do
    html = render('zone_section')
    expect(html).to include('Garage').and include('Garage sensor')
    expect(html).not_to include('Sample Kettle Plug')
  end

  it 'marks an unreachable device instead of drawing its last known readings' do
    html = render('zone_section')
    expect(html).to include('Unreachable')
    expect(html).not_to include('9999')
  end

  it 'sums power and picks the top consumer out of the raw device list' do
    expect(render('energy')).to include('1840').and include('Sample Kettle Plug')
  end

  it 'gives every homey sample device the fields the companion app emits, since samples add devices the capture lacks' do
    %w[energy climate home_status zone_section weather solar].each do |name|
      catalog.find(name).sample['devices'].each do |device|
        expect(device.keys.sort).to eq(WIRE_FIELDS), "#{name} sample device #{device['name']} does not match the wire shape"
      end
    end
    expect(catalog.find('device_card').sample['device'].keys.sort).to eq(WIRE_FIELDS)
  end

  it 'keeps web/seeds/data.json — the payload bin/push-snapshot sends and RECIPES.md calls a real capture — on the wire shape' do
    snapshot = JSON.parse(File.read(File.join(ROOT, 'web/seeds/data.json')))
    snapshot['devices'].each do |device|
      expect(device.keys.sort).to eq(WIRE_FIELDS), "captured device #{device['name']} has drifted from the wire shape"
    end
  end

  it 'reads temperature, humidity and wind off the matched weather device' do
    html = render('weather')
    expect(html).to include('12.4').and include('63').and include('14')
    expect(html).to include('km/h')
  end

  it 'totals live power and cumulative energy for the matched inverter' do
    html = render('solar')
    expect(html).to include('820').and include('6.4').and include('kWh')
  end

  it 'restricts weather and solar to the matched device, not the whole home' do
    solar = catalog.find('solar')
    unmatched = renderer.render(solar, size: 'full', data: solar.sample.merge('match' => 'Nothing'))
    expect(unmatched).to include('0 W')
    expect(unmatched).not_to include('Liquid error')
  end

  it 'averages temperature and humidity across reachable climate sensors' do
    html = render('climate')
    expect(html).to include('19.6').and include('51%')
    expect(html).not_to include('99'), 'the unreachable sensor must not skew the averages'
  end

  it 'makes a lone sensor the climate hero instead of averaging one value' do
    solo = catalog.find('climate').sample['devices'].first(1)
    html = renderer.render(catalog.find('climate'), size: 'full', data: { 'devices' => solo })
    expect(html).to include('Thermometer SNZB-02D')
    expect(html).not_to include('Average')
  end

  it 'shows the climate empty state when no device reports temperature' do
    html = renderer.render(catalog.find('climate'), size: 'full', data: { 'devices' => [] })
    expect(html).to include('No temperature sensors yet')
  end

  it 'chips each active alarm with its zone on the status screen' do
    html = render('home_status')
    expect(html).to include('Kitchen: smoke').and include('Hall: contact')
  end

  it 'reports all clear when no alarms are active' do
    calm = catalog.find('home_status').sample['devices'].reject { |device| device['alarms'].any? }
    html = renderer.render(catalog.find('home_status'), size: 'full', data: { 'devices' => calm })
    expect(html).to include('All clear')
  end

  it 'shows the energy empty state when nothing reports power' do
    unpowered = catalog.find('climate').sample['devices']
    html = renderer.render(catalog.find('energy'), size: 'full', data: { 'devices' => unpowered })
    expect(html).to include('No power readings yet')
  end

  it 'summarizes the insight series as latest reading and 24h range' do
    html = render('insights')
    expect(html).to include('19.4°C').and include('18.1').and include('21.9')
  end

  it 'shows the insights empty state without a series' do
    html = renderer.render(catalog.find('insights'), size: 'full', data: {})
    expect(html).to include('No insight data yet')
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

  it 'renders every component from its bundle alone as it does from the whole catalog, which previews always use' do
    catalog.components.each do |component|
      isolated = render_scope(catalog.bundle_for(component), component)
      complete = render_scope(catalog.shared_markup, component)
      expect(isolated).to eq(complete), "#{component.name} needs more than its bundle to render"
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
