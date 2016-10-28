require 'spec_helper'

RSpec.describe ApiPresenter::Resolvers::Base do

  let(:current_user) { User.new }
  let(:relation) { double('relation') }
  let(:presenter) { PostPresenter.new(current_user: current_user, relation: relation) }
  let(:resolver) { described_class.new(presenter) }

  describe '.initialize' do
    it 'sets presenter' do
      expect(resolver.presenter).to eq(presenter)
    end
  end

  describe 'delegates' do
    it 'delegates current_user to presenter' do
      expect(resolver.current_user).to eq(presenter.current_user)
    end

    it 'delegates relation to presenter' do
      expect(resolver.relation).to eq(presenter.relation)
    end
  end
end
