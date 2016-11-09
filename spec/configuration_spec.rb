require "spec_helper"

describe ApiPresenter::Configuration do

  describe '.initialize' do
    let(:configuration) { ApiPresenter::Configuration.new }

    it 'sets defaults' do
      expect(configuration.count_param).to eq(:count)
      expect(configuration.include_param).to eq(:include)
      expect(configuration.policies_param).to eq(:policies)
    end
  end

  describe '.configure' do
    let(:configuration) { ApiPresenter.configuration }

    before(:each) do
      ApiPresenter.configure do |config|
        config.count_param = :foo
        config.include_param = :bar
        config.policies_param = :cat
      end
    end

    it 'sets user values' do
      [
        { key: :count_param, value: :foo },
        { key: :include_param, value: :bar },
        { key: :policies_param, value: :cat },
      ].each do |config|
        expect(configuration.send(config[:key])).to eq(config[:value])
      end
    end
  end
end
