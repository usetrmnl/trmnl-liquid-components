# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'storybook/app'

RSpec.describe Storybook::App do
  include Rack::Test::Methods
  def app = described_class

  it 'lists components on the index' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Energy')
  end

  it 'renders a component frame as standalone HTML' do
    get '/c/cap_tile/full.html'
    expect(last_response).to be_ok
    expect(last_response.body).to include('1,240').and include('plugins.css')
  end

  it 're-renders a component from posted JSON data' do
    post '/c/cap_tile/full/render', { value: '777', label: 'X', unit: 'W' }.to_json, 'CONTENT_TYPE' => 'application/json'
    expect(last_response.body).to include('777')
  end

  it '404s an unknown component' do
    get '/c/nope/full.html'
    expect(last_response.status).to eq(404)
  end
end
