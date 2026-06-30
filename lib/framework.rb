# frozen_string_literal: true

module Storybook
  # Wraps rendered component HTML in the TRMNL design-system frame so a preview
  # looks like production e-ink. CSS/JS are served per-version from the TRMNL CDN.
  # Pinned so previews are reproducible (matches trmnlp's pin-not-drift behaviour).
  module Framework
    VERSION = '3.1.1'
    SIZES = %w[full half_horizontal half_vertical quadrant].freeze

    def self.css_url = "https://trmnl.com/css/#{VERSION}/plugins.css"
    def self.js_url  = "https://trmnl.com/js/#{VERSION}/plugins.js"

    def self.wrap(inner_html, size:)
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <link rel="stylesheet" href="#{css_url}" />
            <script src="#{js_url}"></script>
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap" rel="stylesheet">
          </head>
          <body class="environment trmnl">
            <div class="screen">
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
