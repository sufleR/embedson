require 'spec_helper'

describe Embedson::Model::MethodBuilder do

  describe '#hash_method' do
    context 'when option :hash_method is defined' do
      let(:builder) { described_class.new(nil, :name, { hash_method: 'method' }) }

      it 'returns its value' do
        expect(builder.hash_method).to eq 'method'
      end
    end

    context 'when options :hash_method is not defined' do
      let(:builder) { described_class.new(nil, :name, {}) }

      it 'returns :to_h' do
        expect(builder.hash_method).to eq :to_h
      end
    end
  end
end
