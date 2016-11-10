require 'spec_helper'

RSpec.describe ApiPresenter::Concerns::Presentable do

  describe '#present' do
    context 'with model that has corresponding presenter' do
      let(:klass) { Post }
      let(:presenter_klass) { PostPresenter }

      it_behaves_like 'a presented collection'
    end

    context 'with model that does not have a corresponding presenter' do
      let(:klass) { Category }
      let(:presenter_klass) { ApiPresenter::Base }

      it_behaves_like 'a presented collection'

      context 'when ApplicationApiPresenter has been defined' do
        before(:each) do
          stub_const("ApplicationApiPresenter", Class.new)
        end

        let(:presenter_klass) { ApplicationApiPresenter }

        it_behaves_like 'a presented collection'
      end
    end
  end
end
