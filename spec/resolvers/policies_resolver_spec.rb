require 'spec_helper'

RSpec.describe ApiPresenter::Resolvers::PoliciesResolver do

  it 'acts like a base resolver' do
    expect(described_class < ApiPresenter::Resolvers::Base).to eq(true)
  end

  let(:current_user) { User.new }
  let(:relation) { double('relation') }
  let(:policy_associations) { [] }
  let(:presenter) { PostPresenter.new(current_user: current_user, relation: relation) }
  let(:resolver) { described_class.new(presenter) }

  before(:each) do
    allow(presenter).to receive(:policy_associations).and_return(policy_associations)
    allow(presenter).to receive(:preload)
  end

  describe '.initialize' do
    it 'sets presenter' do
      expect(resolver.presenter).to eq(presenter)
    end

    context 'when relation is not an ActiveRecord::Relation' do
      it 'does not perform a preload' do
        resolver
        expect(presenter).not_to have_received(:preload)
      end
    end

    context 'when relation is an ActiveRecord::Relation' do
      let(:relation) { Post.all }

      context 'when policy_associations empty' do
        it 'does not perform a preload' do
          resolver
          expect(presenter).not_to have_received(:preload)
        end
      end

      context 'when policy_associations present' do
        let(:policy_associations) { [:foos] }

        it 'preloads policy associations' do
          resolver
          expect(presenter).to have_received(:preload).with(policy_associations)
        end
      end
    end
  end

  describe '#call' do
    let!(:record) { Post.create! }
    let!(:record2) { Post.create! }

    let(:record_policy) { double('policy', update?: true, destroy?: false) }
    let(:record2_policy) { double('policy', update?: true, destroy?: true) }

    let(:id_attribute) { "post_id" }
    let(:resolved_policies) {
      [
        { :"#{id_attribute}" => record.id, update: record_policy.update?, destroy: record_policy.destroy? },
        { :"#{id_attribute}" => record2.id, update: record2_policy.update?, destroy: record2_policy.destroy? }
      ]
    }

    let(:policy_methods) { [:update, :destroy] }

    before(:each) do
      allow(presenter).to receive(:policy_methods).and_return(policy_methods)
      expect(Pundit).to receive(:policy).with(current_user, record).and_return(record_policy)
      expect(Pundit).to receive(:policy).with(current_user, record2).and_return(record2_policy)
    end

    context 'when relation is an ActiveRecord::Relation' do
      let(:relation) { Post.where(id: [record.id, record2.id]) }

      it 'sets resolved_policies' do
        resolver.call
        expect(resolver.resolved_policies).to eq(resolved_policies)
      end
    end

    context 'when relation is a record Array' do
      let(:relation) { [record, record2] }

      it 'sets resolved_policies' do
        resolver.call
        expect(resolver.resolved_policies).to eq(resolved_policies)
      end
    end
  end

  describe 'delegates' do
    it 'delegates policy_associations to presenter' do
      expect(resolver.policy_associations).to eq(presenter.policy_associations)
    end

    it 'delegates policy_methods to presenter' do
      expect(resolver.policy_methods).to eq(presenter.policy_methods)
    end
  end
end
