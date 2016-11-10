require 'spec_helper'

RSpec.describe ApiPresenter::Concerns::Presentable do

  let(:current_user) { User.new }
  let(:params) { { include: "foo,bar", policies: true } }
  let(:controller) { Controller.new(current_user, params) }
  let(:presenter) { double('presenter') }

  describe '#present' do
    before(:each) do
      allow(Query).to receive(:records).and_return(relation_or_record)
    end

    context 'with model that has corresponding presenter' do
      before(:each) do
        allow(PostPresenter).to receive(:call).and_return(presenter)
      end

      context 'with ActiveRecord::Relation' do
        let(:relation_or_record) { Post.all }

        it 'calls model presenter with relation' do
          controller.action
          expect_present(PostPresenter, current_user, relation_or_record)
        end
      end

      context 'with record array' do
        let(:relation_or_record) { [Post.new] }

        it 'calls model presenter with record array' do
          controller.action
          expect_present(PostPresenter, current_user, relation_or_record)
        end
      end

      context 'with single record' do
        let(:relation_or_record) { Post.new }

        it 'calls model presenter with array-wrapped record' do
          controller.action
          expect_present(PostPresenter, current_user, [relation_or_record])
        end
      end
    end

    context 'with model that does not have a corresponding presenter' do
      before(:each) do
        allow(ApiPresenter::Base).to receive(:call).and_return(presenter)
      end

      context 'with ActiveRecord::Relation' do
        let(:relation_or_record) { Category.all }

        it 'calls base presenter with relation' do
          controller.action
          expect_present(ApiPresenter::Base, current_user, relation_or_record)
        end
      end

      context 'with record array' do
        let(:relation_or_record) { [Category.new] }

        it 'calls base presenter with record array' do
          controller.action
          expect_present(ApiPresenter::Base, current_user, relation_or_record)
        end
      end

      context 'with single record' do
        let(:relation_or_record) { Category.new }

        it 'calls base presenter with array-wrapped record' do
          controller.action
          expect_present(ApiPresenter::Base, current_user, [relation_or_record])
        end
      end

      context 'when an application presenter exists' do
        before(:each) do
          stub_const("ApplicationApiPresenter", Class.new)
          allow(ApplicationApiPresenter).to receive(:call).and_return(presenter)
        end

        context 'with ActiveRecord::Relation' do
          let(:relation_or_record) { Category.all }

          it 'calls application presenter with relation' do
            controller.action
            expect_present(ApplicationApiPresenter, current_user, relation_or_record)
          end
        end

        context 'with record array' do
          let(:relation_or_record) { [Category.new] }

          it 'calls application presenter with record array' do
            controller.action
            expect_present(ApplicationApiPresenter, current_user, relation_or_record)
          end
        end

        context 'with single record' do
          let(:relation_or_record) { Category.new }

          it 'calls application presenter with array-wrapped record' do
            controller.action
            expect_present(ApplicationApiPresenter, current_user, [relation_or_record])
          end
        end
      end
    end
  end

  private

  def expect_present(presenter_klass, current_user, relation_or_record)
    expect(presenter_klass).to have_received(:call).with(
      current_user: current_user,
      relation:     relation_or_record,
      params:       controller.params
    )
  end

end
