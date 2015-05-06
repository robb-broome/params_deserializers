require 'spec_helper'

class StubController < ActionController::Base
  include ParamsDeserializers

  deserialize_params_with(Class.new(ParamsDeserializer) do
    attributes :foo
  end, only: :update)

  def update
    render text: ''
  end
end

describe StubController, type: :controller do
  around :each do |example|
    Rails.application.routes.draw { get '/stub_controller' => 'stub#update' }
    example.run
    Rails.application.reload_routes!
  end

  it 'can call the deserialized_params getter' do
    put :update
    expect(controller).to respond_to :deserialized_params
  end

  it 'gets deserialized params when calling the deserialized_params getter' do
    put :update, foo: 'bar', baz: 'quux'
    expect(controller.deserialized_params).to eql('foo' => 'bar')
  end

  it 'gets a HashWithIndifferentAccess from the deserialized_params getter' do
    put :update, foo: 'bar'
    expect(controller.deserialized_params).to be_a ::ActiveSupport::HashWithIndifferentAccess
  end
end