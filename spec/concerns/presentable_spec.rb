require 'spec_helper'

RSpec.describe ApiPresenter::Concerns::Presentable do

  let(:current_user) { User.new }
  let(:params) { { include: "categories,subCategories,posts", policies: true } }
  let(:controller) { PostsController.new(current_user, params) }

  describe '#present' do
    let(:presenter) { double('presenter') }

    before(:each) do
      allow(PostPresenter).to receive(:call).and_return(presenter)
    end

    context 'with multiple records' do
      before(:each) do
        allow(PostQuery).to receive(:records).and_return(records)
      end

      context 'with ActiveRecord::Relation' do
        let(:records) { Post.all }

        it 'calls presenter with relation' do
          controller.index
          expect_present(PostPresenter, current_user, records)
        end
      end

      context 'with record array' do
        let(:records) { [Post.new] }

        it 'calls presenter with record array' do
          controller.index
          expect_present(PostPresenter, current_user, records)
        end
      end
    end

    context 'with single record' do
      let(:record) { Post.new }

      before(:each) do
        allow(Post).to receive(:find).and_return(record)
      end

      it 'calls presenter with array-wrapped record' do
        controller.show
        expect_present(PostPresenter, current_user, [record])
      end
    end
  end

  private

  def expect_present(presenter_klass, current_user, relation)
    expect(presenter_klass).to have_received(:call).with(
      current_user: current_user,
      relation:     relation,
      params:       controller.params
    )
  end

end
