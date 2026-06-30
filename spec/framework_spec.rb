# frozen_string_literal: true

require 'spec_helper'
require 'framework'

RSpec.describe Storybook::Framework do
  describe '.wrap' do
    subject(:html) { described_class.wrap('<p>hi</p>', size: 'full') }

    it 'links the pinned framework stylesheet' do
      expect(html).to include('https://trmnl.com/css/3.1.1/plugins.css')
    end

    it 'wraps the inner html in the view container for the size' do
      expect(html).to include('view view--full').and include('<p>hi</p>')
    end
  end
end
