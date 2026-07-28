# frozen_string_literal: true

module Storybook
  # Wraps rendered component HTML in the TRMNL design-system frame so a preview
  # looks like production e-ink. CSS/JS are served per-version from the TRMNL CDN.
  # Pinned so previews are reproducible (matches trmnlp's pin-not-drift behaviour).
  module Framework
    VERSION = '3.1.1'
    SIZES = %w[full half_horizontal half_vertical quadrant].freeze

    # Responsive utilities key off device-set classes, not media queries — a preview without them silently renders the base tier no device shows.
    DEVICES = {
      'og' => { label: 'TRMNL OG', screen: 'screen--md screen--1bit', width: 800, height: 480, gap: 10 },
      'x' => { label: 'TRMNL X', screen: 'screen--lg screen--4bit', width: 1872, height: 1404, gap: 18 }
    }.freeze

    DEFAULT_DEVICE = 'og'

    def self.css_url = "https://trmnl.com/css/#{VERSION}/plugins.css"
    def self.js_url  = "https://trmnl.com/js/#{VERSION}/plugins.js"

    def self.device(name) = DEVICES.fetch(name || DEFAULT_DEVICE)

    # The framework bakes a literal screen size into each layout variable rather than
    # deriving them at use time, so overriding --screen-w alone leaves every view at
    # OG dimensions. A device preview has to restate the whole family.
    def self.screen_variables(spec)
      width, height, gap = spec.values_at(:width, :height, :gap)
      half_width = (width - (gap * 3)) / 2
      half_height = (height - (gap * 3)) / 2
      {
        'screen-w' => width, 'screen-h' => height, 'gap' => gap,
        'full-w' => width - (gap * 2), 'full-h' => height - (gap * 2),
        'half_horizontal-w' => width - (gap * 2), 'half_horizontal-h' => half_height,
        'half_vertical-w' => half_width, 'half_vertical-h' => height - (gap * 2),
        'quadrant-w' => half_width, 'quadrant-h' => half_height
      }.map { |name, value| "--#{name}: #{value}px;" }.join(' ')
    end

    def self.wrap(inner_html, size:, device: DEFAULT_DEVICE)
      spec = device(device)
      screen = spec[:screen]
      screen_style = screen_variables(spec)
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <link rel="stylesheet" href="#{css_url}" />
            <script src="#{js_url}"></script>
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap" rel="stylesheet">
          </head>
          <body class="environment trmnl" style="#{screen_style}">
            <div class="screen #{screen}">
              <div class="view view--#{size}">
                #{inner_html}
              </div>
            </div>
          </body>
        </html>
      HTML
    end
  end
end
