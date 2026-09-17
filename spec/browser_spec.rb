# frozen_string_literal: true

require 'spec_helper'
require 'ferrum'
require 'json'
require 'tmpdir'
require 'storybook/catalog'
require 'storybook/site'
require 'storybook/renderer'

# Loads the built site in headless Chrome. Server-side specs cannot see either of
# these failures: a screen that paints past the device edge still renders fine as
# a string, and a gallery whose JavaScript throws still serves valid HTML.
RSpec.describe 'the built site in a browser', :browser do
  # Paint past the view's edge — the framework clips overflow, so scrollHeight never moves; only geometry catches a spill.
  SPILL = <<~JS
    (() => {
      const view = document.querySelector('.view');
      const edge = view.getBoundingClientRect();
      let down = 0, across = 0;
      view.querySelectorAll('*').forEach((el) => {
        const box = el.getBoundingClientRect();
        if (box.height === 0 && box.width === 0) return;
        down = Math.max(down, box.bottom - edge.bottom);
        across = Math.max(across, box.right - edge.right);
      });
      return { down: Math.round(down), across: Math.round(across) };
    })()
  JS

  # A recipe's content lives in its `.layout`; the title bar sits below it. Centered
  # content spills past the top as much as the bottom, so measure every edge.
  LAYOUT_SPILL = <<~JS
    (() => {
      const layout = document.querySelector('.layout');
      const edge = layout.getBoundingClientRect();
      const spill = { up: 0, down: 0, across: 0 };
      layout.querySelectorAll('*').forEach((el) => {
        const box = el.getBoundingClientRect();
        if (box.height === 0 && box.width === 0) return;
        spill.up = Math.max(spill.up, edge.top - box.top);
        spill.down = Math.max(spill.down, box.bottom - edge.bottom);
        spill.across = Math.max(spill.across, box.right - edge.right);
      });
      return Object.fromEntries(Object.entries(spill).map(([k, v]) => [k, Math.round(v)]));
    })()
  JS

  before(:all) do
    @root = Dir.mktmpdir
    Storybook::Site.new(Storybook::Catalog.load(File.join(ROOT, 'components'))).build(@root)
    @browser = Ferrum::Browser.new(headless: true, timeout: 30)
    @page = @browser.create_page
  end

  after(:all) do
    @browser&.quit
    FileUtils.remove_entry(@root) if @root
  end

  it 'paints every preview inside its device screen, on every device' do
    spilling = Dir.glob("#{@root}/c/*/*/*/*.html").sort.filter_map do |path|
      @page.go_to("file://#{path}")
      sleep 0.6
      spill = @page.evaluate(SPILL)
      next if spill['down'] <= 1 && spill['across'] <= 1

      "#{path.delete_prefix("#{@root}/c/").delete_suffix('.html')} (#{spill['down']}px down, #{spill['across']}px across)"
    end
    expect(spilling).to be_empty, "previews painting outside the screen:\n  #{spilling.join("\n  ")}"
  end

  # The shipped seed is a two-device home, which any layout fits. This one is the
  # seven-device, three-zone home core ships as the plugin's demo world.
  it 'paints every recipe inside an OG screen for a seven-device home' do
    renderer = Storybook::Renderer.new(Storybook::Catalog.load(File.join(ROOT, 'components')))
    home = JSON.parse(File.read(File.join(ROOT, 'web/seeds/family_home.json')))
    spilling = Dir.glob(File.join(ROOT, 'recipes', '*.liquid')).sort.filter_map do |recipe|
      path = File.join(@root, "recipe-#{File.basename(recipe, '.liquid')}.html")
      File.write(path, renderer.render_markup(File.read(recipe), size: 'full', data: { 'homey' => home }))
      @page.go_to("file://#{path}")
      sleep 0.6
      spill = @page.evaluate(LAYOUT_SPILL)
      next if spill.values.max <= 1

      "#{File.basename(recipe)} (#{spill.map { |edge, px| "#{px}px #{edge}" }.join(', ')})"
    end
    expect(spilling).to be_empty, "recipes painting outside the screen:\n  #{spilling.join("\n  ")}"
  end

  it 'scales type up on X, so a preview is not OG-sized on a screen three times the area' do
    og = "#{@root}/c/stat/default/og/full.html"
    x  = "#{@root}/c/stat/default/x/full.html"
    sizes = [og, x].map do |path|
      @page.go_to("file://#{path}")
      sleep 0.6
      @page.evaluate('parseInt(getComputedStyle(document.querySelector(".value")).fontSize, 10)')
    end
    expect(sizes.last).to be > sizes.first
  end

  it 'runs the gallery script far enough to select a component' do
    @page.go_to("file://#{@root}/index.html")
    sleep 1
    expect(@page.evaluate('document.getElementById("title").textContent')).not_to be_empty
    expect(@page.evaluate('document.getElementById("bundle").textContent.length')).to be > 0
    expect(@page.evaluate('document.getElementById("preview").src')).to include('/c/')
  end
end
