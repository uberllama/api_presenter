require 'spec_helper'

RSpec.describe ApiPresenter::Resolvers::IncludedCollectionsResolver do

  it 'acts like a base resolver' do
    expect(described_class < ApiPresenter::Resolvers::Base).to eq(true)
  end

  let(:current_user) { User.new }
  let(:relation) { Post.all }
  let(:associations_map) {
    {
      categories:     { associations: { sub_category: :category } },
      sub_categories: { associations: :sub_category },
      users:          { associations: [:creator, :publisher] }
    }
  }
  let(:included_collection_names) { [] }
  let(:presenter) { PostPresenter.new(current_user: current_user, relation: relation) }
  let(:resolver) { described_class.new(presenter) }

  before(:each) do
    allow(presenter).to receive(:associations_map).and_return(associations_map)
    allow(presenter).to receive(:included_collection_names).and_return(included_collection_names)
    allow(presenter).to receive(:preload)
  end

  describe '.initialize' do
    it 'sets presenter' do
      expect(resolver.presenter).to eq(presenter)
    end

    context 'when relation is not an ActiveRecord::Relation' do
      let(:relation) { double('relation') }

      it 'does not perform a preload' do
        resolver
        expect(presenter).not_to have_received(:preload)
      end
    end

    context 'when relation is an ActiveRecord::Relation' do
      context 'when associations_map undefined on presenter' do
        let(:associations_map) { {} }

        it 'does not perform a preload' do
          resolver
          expect(presenter).not_to have_received(:preload)
        end
      end

      context 'when associations_map defined on presenter' do
        let(:included_collection_names) { [:categories, :sub_categories, :users] }

        let(:category_authorized?) { true }
        let(:category_policy) { double('policy', index?: category_authorized?) }

        let(:sub_category_authorized?) { true }
        let(:sub_category_policy) { double('policy', index?: sub_category_authorized?) }

        let(:user_authorized?) { true }
        let(:user_policy) { double('policy', index?: user_authorized?) }

        before(:each) do
          expect(Pundit).to receive(:policy).with(current_user, Category).and_return(category_policy)
          expect(Pundit).to receive(:policy).with(current_user, SubCategory).and_return(sub_category_policy)
          expect(Pundit).to receive(:policy).with(current_user, User).and_return(user_policy)
        end

        context 'when valid and authorized' do
          it 'preloads resolved and flattened associations' do
            resolver
            expect(presenter).to have_received(:preload).with(
              [{ sub_category: :category }, :sub_category, :creator, :publisher]
            )
          end
        end

        context 'with invalid collection name' do
          before(:each) do
            included_collection_names << :foos
          end

          it 'preloads only valid resolved associations' do
            resolver
            expect(presenter).to have_received(:preload).with(
              [{ sub_category: :category }, :sub_category, :creator, :publisher]
            )
          end
        end

        context 'with unpermitted collection policy' do
          let(:user_authorized?) { false }

          it 'preloads only permitted resolved associations' do
            resolver
            expect(presenter).to have_received(:preload).with(
              [{ sub_category: :category }, :sub_category]
            )
          end
        end

        context 'with inline condition' do
          before(:each) do
            associations_map[:users].merge!(condition: 'current_user.admin?')
            expect(current_user).to receive(:admin?).and_return(condition_result)
          end

          context 'when pass' do
            let(:condition_result) { true }

            it 'preloads resolved associations' do
              resolver
              expect(presenter).to have_received(:preload).with(
                [{ sub_category: :category }, :sub_category, :creator, :publisher]
              )
            end
          end

          context 'when fail' do
            let(:condition_result) { false }

            it 'preloads only passing resolved associations' do
              resolver
              expect(presenter).to have_received(:preload).with(
                [{ sub_category: :category }, :sub_category]
              )
            end
          end
        end

        context 'with method condition' do
          before(:each) do
            associations_map[:users].merge!(condition: :admin?)
            expect(presenter).to receive(:admin?).and_return(condition_result)
          end

          context 'when pass' do
            let(:condition_result) { true }

            it 'preloads resolved associations' do
              resolver
              expect(presenter).to have_received(:preload).with(
                [{ sub_category: :category }, :sub_category, :creator, :publisher]
              )
            end
          end

          context 'when fail' do
            let(:condition_result) { false }

            it 'preloads only passing resolved associations' do
              resolver
              expect(presenter).to have_received(:preload).with(
                [{ sub_category: :category }, :sub_category]
              )
            end
          end
        end
      end
    end
  end

  describe 'delegates' do
    it 'delegates associations_map to presenter' do
      expect(resolver.associations_map).to eq(presenter.associations_map)
    end

    it 'delegates included_collection_names to presenter' do
      expect(resolver.included_collection_names).to eq(presenter.included_collection_names)
    end
  end

  describe '#call' do
    let(:included_collection_names) { [:categories, :sub_categories, :users] }

    let!(:category) { Category.create! }

    let!(:sub_category) { category.sub_categories.create! }
    let!(:sub_category2) { category.sub_categories.create! }

    let!(:creator) { User.create! }
    let!(:creator2) { User.create! }
    let!(:publisher) { User.create! }

    let!(:record) { Post.create!(sub_category: sub_category, creator: creator, publisher: publisher) }
    let!(:record2) { Post.create!(sub_category: sub_category2, creator: creator2, publisher: publisher) }
    let(:relation) { Post.where(id: [record.id, record2.id]) }

    let(:policy) { double('policy', index?: true) }

    before(:each) do
      allow(Pundit).to receive(:policy).and_return(policy)
    end

    it 'loads uniq records for singular association definitions' do
      resolver.call
      expect(resolver.resolved_collections[:categories]).to eq([category])
    end

    it 'loads uniq records for multiple association definitions' do
      resolver.call
      expect(resolver.resolved_collections[:users]).to eq([creator, creator2, publisher])
    end

    it 'loads uniq records for nested association definitions' do
      resolver.call
      expect(resolver.resolved_collections[:sub_categories]).to eq([sub_category, sub_category2])
    end
  end
end
