require 'rails_helper'

RSpec.describe TalksController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/talks').to route_to('talks#index')
    end

    it 'routes to #monthly' do
      expect(:get => '/talks/monthly').to route_to('talks#monthly')
    end

    it 'routes to #autocomplete_tag_name' do
      expect(:get => '/talks/autocomplete_tag_name').to route_to('talks#autocomplete_tag_name')
    end

    it 'routes to #new' do
      expect(:get => '/talks/new').to route_to('talks#new')
    end

    it 'routes to #show' do
      expect(:get => '/talks/1').to route_to('talks#show', :id => '1')
    end

    it 'routes to #edit' do
      expect(:get => '/talks/1/edit').to route_to('talks#edit', :id => '1')
    end

    it 'routes to #cancel' do
      expect(:get => '/talks/1/cancel').to route_to('talks#cancel', :id => '1')
    end

    it 'routes to #preview_publish' do
      expect(:get => '/talks/1/preview_publish').to route_to('talks#preview_publish', :id => '1')
    end

    it 'routes to #preview_cover_image' do
      expect(:get => '/talks/1/preview_cover_image').to route_to('talks#preview_cover_image', :id => '1')
    end

    it 'routes to #create' do
      expect(:post => '/talks').to route_to('talks#create')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/talks/1').to route_to('talks#update', :id => '1')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/talks/1').to route_to('talks#update', :id => '1')
    end

    it 'routes to #publish via PATCH' do
      expect(:patch => '/talks/1/publish').to route_to('talks#publish', :id => '1')
    end

    it 'routes to #destroy' do
      expect(:delete => '/talks/1').to route_to('talks#destroy', :id => '1')
    end

  end
end
