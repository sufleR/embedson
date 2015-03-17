require 'spec_helper'

describe Embedson::Model::EmbedsBuilder do

  with_model :Parent do
    table do |t|
      t.json :son_col
    end

    model do
      embeds_one :son, column_name: :son_col, class_name: FirstSon
    end
  end

  class FirstSon < OpenStruct
    extend Embedson::Model

    embedded_in :parent, inverse_of: :son

  end

  class FirstSonsChild < FirstSon
  end

  describe 'defined #son method' do
    context 'when child of embedded model is assigned as son' do
      let(:parent) { Parent.new(son: son) }
      let(:son) { FirstSonsChild.new(some: 'random') }

      it 'returns SonsChild instance' do
        expect(parent.son).to be_a FirstSonsChild
        expect(parent.son).to eq son
      end

      context 'when aprent is persisted' do
        before do
          parent.save!
        end

        it 'returns SonsChild instance' do
          expect(parent.reload.son).to be_a FirstSonsChild
          expect(parent.son).to eq son
        end
      end
    end
  end
end
