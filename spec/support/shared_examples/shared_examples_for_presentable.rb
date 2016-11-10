RSpec.shared_examples_for "a presented collection" do
  let(:current_user) { User.new }
  let(:params) { { include: "foo,bar", policies: true } }
  let(:controller) { Controller.new(current_user, params) }
  let(:presenter) { double('presenter') }

  before(:each) do
    allow(Query).to receive(:records).and_return(relation_or_record)
    allow(presenter_klass).to receive(:call).and_return(presenter)
  end

  context 'with ActiveRecord::Relation' do
    let(:relation_or_record) { klass.all }

    it 'calls presenter with relation' do
      controller.action
      expect_present(relation_or_record)
    end
  end

  context 'with record array' do
    let(:relation_or_record) { [klass.new] }

    it 'calls presenter with record array' do
      controller.action
      expect_present(relation_or_record)
    end
  end

  context 'with single record' do
    let(:relation_or_record) { klass.new }

    it 'calls presenter with array-wrapped record' do
      controller.action
      expect_present([relation_or_record])
    end
  end
end
