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
    post '/c/cap_tile/full/render', { data: { value: '777', label: 'X', unit: 'W' } }.to_json, 'CONTENT_TYPE' => 'application/json'
    expect(last_response.body).to include('777')
  end

  it 'shows the energy chart by default' do
    post '/c/energy/full/render', { data: {} }.to_json, 'CONTENT_TYPE' => 'application/json'
    expect(last_response.body).to include('homey-energy-chart')
  end

  it 'applies posted options that alter the render' do
    post '/c/energy/full/render', { data: {}, options: { show_chart: 'no' } }.to_json, 'CONTENT_TYPE' => 'application/json'
    expect(last_response.body).not_to include('homey-energy-chart')
  end

  it '404s an unknown component' do
    get '/c/nope/full.html'
    expect(last_response.status).to eq(404)
  end

  it 'serves the preview playground page' do
    get '/preview'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Preview playground')
  end

  it 'renders pasted markup against posted data, framed like a plugin' do
    body = { markup: '<b>{{ devices | size }}</b>', data: { devices: [{ name: 'A' }, { name: 'B' }] } }.to_json
    post '/preview/full', body, 'CONTENT_TYPE' => 'application/json'
    expect(last_response.body).to include('<b>2</b>').and include('view view--full')
  end

  it '422s malformed preview JSON' do
    post '/preview/full', '{not json', 'CONTENT_TYPE' => 'application/json'
    expect(last_response.status).to eq(422)
  end
end
