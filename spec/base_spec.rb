require 'spec_helper'

RSpec.describe ApiPresenter::Base do

  let(:current_user) { User.new }
  let(:relation) { double('relation') }
  let(:count_param) { nil }
  let(:include_param) { nil }
  let(:policies_param) { nil }
  let(:params) { { count: count_param, include: include_param, policies: policies_param } }
  let(:presenter) { described_class.new(current_user: current_user, relation: relation, params: params) }


  describe '.call' do
    let(:call_presenter) {
      described_class.call(current_user: current_user, relation: relation, params: params)
    }

    it 'initializes and calls service' do
      expect(described_class).to receive(:new).
        with(current_user: current_user, relation: relation, params: params).
        and_return(presenter)
      expect(presenter).to receive(:call)
      call_presenter
    end
  end

  describe '.initialize' do
    it 'sets current_user' do
      expect(presenter.current_user).to eq(current_user)
    end

    it 'sets relation' do
      expect(presenter.relation).to eq(relation)
    end

    it 'sets params' do
      expect(presenter.params).to eq(params)
    end
  end

  describe '#call' do
    let(:resolved_policies) { double('resolved_policies') }
    let(:policies_resolver) { double('policies_resolver', resolved_policies: resolved_policies) }

    let(:resolved_collections) { double('resolved_collections') }
    let(:included_collections_resolver) { double('included_collections_resolver', resolved_collections: resolved_collections) }

    before(:each) do
      allow(ApiPresenter::Resolvers::PoliciesResolver).to receive(:new).
        and_return(policies_resolver)
      allow(policies_resolver).to receive(:call)

      allow(ApiPresenter::Resolvers::IncludedCollectionsResolver).to receive(:new).
        and_return(included_collections_resolver)
      allow(included_collections_resolver).to receive(:call)
    end

    context 'when count_only?' do
      let(:count_param) { true }

      it 'does not call resolvers' do
        presenter.call
        expect(ApiPresenter::Resolvers::PoliciesResolver).not_to have_received(:new)
        expect(ApiPresenter::Resolvers::IncludedCollectionsResolver).not_to have_received(:new)
      end

      it 'returns self' do
        expect(presenter.call).to eq(presenter)
      end
    end

    context 'when records requested' do
      context 'without policies' do
        it 'does not call PoliciesResolver' do
          presenter.call
          expect(ApiPresenter::Resolvers::PoliciesResolver).not_to have_received(:new)
        end

        it 'does not set #policies' do
          presenter.call
          expect(presenter.policies).to eq(Hash.new)
        end
      end

      context 'without includes' do
        it 'does not call IncludedCollectionsResolver' do
          presenter.call
          expect(ApiPresenter::Resolvers::IncludedCollectionsResolver).not_to have_received(:new)
        end

        it 'does not set #included_collections' do
          presenter.call
          expect(presenter.included_collections).to eq(Hash.new)
        end
      end

      context 'with policies' do
        let(:policies_param) { true }

        it 'calls PoliciesResolver' do
          presenter.call
          expect(ApiPresenter::Resolvers::PoliciesResolver).to have_received(:new).with(presenter)
          expect(policies_resolver).to have_received(:call)
        end

        it 'sets #policies' do
          presenter.call
          expect(presenter.policies).to eq(resolved_policies)
        end
      end

      context 'with includes' do
        let(:include_param) { 'categories,subCategories,users' }
        let(:included_collection_names) { [:categories, :sub_categories, :users] }

        before(:each) do
          expect(ApiPresenter::Parsers::ParseIncludeParams).to receive(:call).with(include_param).
            and_return(included_collection_names)
        end

        it 'calls IncludedCollectionsResolver' do
          presenter.call
          expect(ApiPresenter::Resolvers::IncludedCollectionsResolver).to have_received(:new).with(presenter)
          expect(included_collections_resolver).to have_received(:call)
        end

        it 'sets #included_collections' do
          presenter.call
          expect(presenter.included_collections).to eq(resolved_collections)
        end
      end
    end
  end

  describe '#collection' do
    context 'when count_only?' do
      let(:count_param) { true }

      it 'returns empty Array' do
        expect(presenter.collection).to eq([])
      end
    end

    context 'when records requested' do
      it 'returns relation' do
        expect(presenter.collection).to eq(relation)
      end
    end
  end

  describe '#total_count' do
    context 'when relation is a paginated object' do
      let(:total_count) { 100 }

      before(:each) do
        allow(relation).to receive(:total_count).and_return(total_count)
      end

      it 'returns total_count' do
        expect(presenter.total_count).to eq(total_count)
      end
    end

    context 'when relation is not a paginated object' do
      let(:count) { 1 }

      before(:each) do
        allow(relation).to receive(:count).and_return(count)
      end

      it 'returns count' do
        expect(presenter.total_count).to eq(count)
      end
    end
  end

  describe '#preload' do
    let(:associations) { [:categroies, :sub_categories, :users] }

    before(:each) do
      allow(relation).to receive(:preload)
    end

    it 'calls preload on relation' do
      presenter.preload(associations)
      expect(relation).to have_received(:preload).with(associations)
    end
  end

  describe '#included_collection_names' do
    let(:include_param) { 'categories,sub_categories,users' }
    let(:included_collection_names) { [:categories,:sub_categories, :users] }

    before(:each) do
      expect(ApiPresenter::Parsers::ParseIncludeParams).to receive(:call).with(include_param).
        and_return(included_collection_names)
    end

    it 'returns parsed collection names' do
      expect(presenter.included_collection_names).to eq(included_collection_names)
    end
  end
end
