require 'spec_helper'

RSpec.describe ApiPresenter::Parsers::ParseIncludeParams do

  describe '.call' do
    context 'when valid' do
      let(:parsed_value) { [:categories, :sub_categories, :posts] }

      [
        'categories,sub_categories,posts',          # Underscored String
        'categories,subCategories,posts',           # camelCased String
        'categories,subCategories,posts,posts',     # String with dups
        'categories,subCategories,posts, ,posts',   # String with blanks
        ['categories', 'sub_categories', 'posts'],  # Array of Strings
        [:categories, :sub_categories, :posts],     # Array of Symbols
        [:categories, 'subCategories', 'posts'],    # United Colors of Benetton
      ].each do |unparsed_value|
        it 'parses value' do
          expect(described_class.call(unparsed_value)).to eq(parsed_value)
        end
      end
    end

    context 'when blank' do
      it 'returns empty Array' do
        expect(described_class.call('')).to eq([])
      end
    end

    context 'when nil' do
      it 'returns empty Array' do
        expect(described_class.call(nil)).to eq([])
      end
    end
  end

end
