# frozen_string_literal: true

require 'json'
require 'sinatra/base'
require_relative 'catalog'
require_relative 'renderer'

module Storybook
  class App < Sinatra::Base
    set :views, File.expand_path('../../web/views', __dir__)
    set :public_folder, File.expand_path('../../web/public', __dir__)
    # Stateless public storybook (no cookies/sessions), so host-header attacks
    # have no surface — allow any host so it serves behind any deploy hostname.
    set :host_authorization, { permitted_hosts: [] }

    class << self
      attr_accessor :catalog
    end

    def catalog = self.class.catalog ||= Catalog.load(File.expand_path('../../components', __dir__))
    def renderer = @renderer ||= Renderer.new(catalog)

    get '/' do
      @catalog = catalog
      erb :index
    end

    get '/c/:name/:size.html' do
      component = catalog.find(params[:name]) or halt 404, 'unknown component'
      renderer.render(component, size: params[:size])
    end

    post '/c/:name/:size/render' do
      component = catalog.find(params[:name]) or halt 404, 'unknown component'
      data = JSON.parse(request.body.read)
      renderer.render(component, size: params[:size], data:)
    rescue JSON::ParserError
      halt 422, 'invalid JSON'
    end
  end
end
