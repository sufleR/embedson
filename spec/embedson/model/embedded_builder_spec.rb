require 'spec_helper'

describe Embedson::Model::EmbeddedBuilder do

  with_model :Parent do
    table do |t|
      t.json :embedded
      t.json :emb_col
    end

    model do
      embeds_one :son, column_name: :embedded
      embeds_one :emb, class_name: Son, inverse_of: :parenta, column_name: :emb_col
    end
  end

  class Son < OpenStruct
    extend Embedson::Model

    embedded_in :parent
    embedded_in :parenta, class_name: 'Parent', inverse_of: :emb
  end

  let(:different) { { 'different' => 'true' } }
  let(:parent) { Parent.new(embedded: different, emb_col: different) }
  let(:son) { Son.new(something: { 'to' => 'write' }, parent: parent, parenta: parent) }

  describe 'defined .parent_send_to_related' do
    context 'when parent responds to son' do
      context 'and to_h is different than parents son.to_h' do
        before do
          son
          parent.send(:write_attribute, :embedded, different)
        end

        it 'changes parents embedded to son.to_h' do
          expect{
            son.send(:parent_send_to_related, son)
          }.to change { parent.embedded }.from('different' => 'true').to(son.to_h.stringify_keys)
        end

      end

      context 'and to_h is equal parents embeded.to_h' do
        before do
          son
          parent.send(:write_attribute, :embedded, { something: { to: 'write' } } )
          parent.save!
        end

        it 'does not register change on parent' do
          expect {
            son.send(:parent_send_to_related, son)
          }.to_not change { parent.changes }
        end

      end
    end

    context 'when parent do not respond to son=' do
      before do
        allow(parent).to receive(:respond_to?).and_return(false)
      end

      it 'raises Embedson::NoRelationDefinedError' do
        expect {
          son.send(:parent_send_to_related, son)
        }.to raise_error(Embedson::NoRelationDefinedError)
      end
    end
  end

  describe 'defined .parenta_send_to_related' do
    context 'when parent responds to emb' do
      context 'and to_h is different than parents emb_col' do
        before do
          son
          parent.send(:write_attribute, :emb_col, different)
        end

        it 'changes parents emb_col to son.to_h' do
          expect{
            son.send(:parenta_send_to_related, son)
          }.to change { parent.emb_col }.from('different' => 'true').to(son.to_h.stringify_keys)
        end

      end

      context 'and to_h is equal parents emb_col' do
        before do
          son
          parent.send(:write_attribute, :embedded, { something: { to: 'write' } } )
          parent.save!
        end

        it 'does not register change on parent' do
          expect {
            son.send(:parenta_send_to_related, son)
          }.to_not change { parent.changes }
        end

      end
    end

    context 'when parent do not respond to emb=' do
      before do
        allow(parent).to receive(:respond_to?).and_return(false)
      end

      it 'raises Embedson::NoRelationDefinedError' do
        expect {
          son.send(:parenta_send_to_related, son)
        }.to raise_error(Embedson::NoRelationDefinedError)
      end
    end
  end

  describe 'defined .save' do
    context 'when there is parent' do
      let(:son) { Son.new(parent: parent, parenta: parent) }

      context 'and parent is new record' do
        it 'saves parent twice' do
          parent
          expect(parent).to receive(:save).twice
          son.save
        end

        it 'saves son to parent' do
          parent
          son.save
          parent.reload
          expect(parent.son).to eq son
          expect(parent.emb).to eq son
        end

      end

      context 'and parent is persisted' do
        let(:son) { Son.new(something: different, parent: parent, parenta: parent) }

        before do
          parent.save!
        end

        it 'changes column values' do
          son.save
          expect(parent.embedded).to eq('something' => different)
          expect(parent.emb_col).to eq('something' => different)
        end
      end
    end
  end
end
