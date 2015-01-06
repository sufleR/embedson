require 'spec_helper'

describe Embedson::Model::EmbeddedBuilder do

  with_model :Parent do
    table do |t|
      t.json :son_col
      t.json :emb_col
    end

    model do
      embeds_one :son, column_name: :son_col
      embeds_one :emb, class_name: Son, inverse_of: :parenta, column_name: :emb_col
    end
  end

  with_model :ParentTwo do
    table do |t|
      t.json :son_col
    end

    model do
      embeds_one :son, column_name: :son_col
    end
  end

  class Son
    extend Embedson::Model

    def initialize(hash = nil)
      @table = {}
      return unless hash
      hash.each do |k,v|
        @table[k.to_sym] = v
      end
    end

    def change=(arg)
      @table['change'] = arg
    end

    def to_h
      @table
    end

    embedded_in :parent
    embedded_in :parenta, class_name: 'Parent', inverse_of: :emb
    embedded_in :parent_two
  end

  let(:different) { { 'different' => 'true' } }
  let(:parent) { Parent.new(son_col: different, emb_col: different) }
  let(:parent_two) { ParentTwo.new(son_col: different) }
  let(:son) { Son.new(something: { 'to' => 'write' }, parent: parent, parenta: parent) }

  describe 'defined .parent_send_to_related' do
    context 'when parent responds to son' do
      context 'and to_h is different than parents son.to_h' do
        before do
          son
          parent.send(:write_attribute, :son_col, different)
        end

        it 'changes parents son_col to son.to_h' do
          expect{
            son.send(:parent_send_to_related, son)
          }.to change { parent.son_col }
           .from('different' => 'true')
           .to(son.to_h.stringify_keys.merge('_type' => 'Parent'))
        end

      end

      context 'and to_h is equal parents embeded.to_h' do
        before do
          son
          parent.send(:write_attribute, :son_col, { something: { to: 'write' }, _type: 'Parent' } )
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
          }.to change { parent.emb_col }
           .from('different' => 'true')
           .to(son.to_h.stringify_keys.merge('_type' => 'Parent'))
        end

      end

      context 'and to_h is equal parents emb_col' do
        before do
          son
          parent.send(:write_attribute, :son_col, { something: { to: 'write' } } )
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
    let(:parent) { Parent.new() }

    context 'when there is no parent' do
      let(:son) { Son.new }

      it 'returns false' do
        expect(son.save).to eq(false)
      end
    end

    context 'when there are parents' do
      let(:son) { Son.new(parent: parent, parent_two: parent_two, something: different) }

      context 'and save on all returns true' do
        it 'returns true' do
          expect(son.save).to eq(true)
        end
      end

      context 'and save on one of them fails' do
        before do
          allow(parent_two).to receive(:save).and_return(false)
        end

        it 'returns false' do
          expect(son.save).to be_falsy
        end

        it 'does not change any of parents' do
          parent.save!
          parent_two.save!
          expect{ son.save }.to_not change{ parent.reload.son_col }
          expect(parent_two.reload.son_col).to eq different
        end
      end

      context 'and parent is new record' do
        it 'saves all parents' do
          parent
          parent_two
          expect(parent).to receive(:save).and_return(true)
          expect(parent_two).to receive(:save).and_return(true)
          son.save
        end

        it 'saves son to parent' do
          parent
          parent_two
          son.save
          parent.reload
          parent_two.reload
          expect(parent.son).to eq son
          expect(parent.emb).to be_nil
          expect(parent_two.son).to eq son
        end
      end

      context 'and parent is persisted' do
        let(:son) { Son.new(something: different, parent: parent, parent_two: parent_two) }

        before do
          parent.save!
        end

        it 'changes column values' do
          son.save
          expect(parent.son_col).to eq('something' => different, '_type' => 'Parent')
          expect(parent.emb_col).to be_nil
          expect(parent_two.son_col).to eq('something' => different, '_type' => 'ParentTwo')
        end

        context 'and son is changed' do
          it 'saves changes in parent' do
            son.save!
            expect {
              son.change = 'new value'
              son.save
            }.to change { parent.reload.son_col }
             .from('something' => different, '_type' => 'Parent')
             .to('something' => different, 'change' => 'new value', '_type' => 'Parent')
            expect(parent_two.son_col).to eq('something' => different, 'change' => 'new value', '_type' => 'ParentTwo')
          end
        end
      end

      context 'and parent is one from many defined' do
        let(:son) { Son.new(parent: parent) }

        context 'and is new record' do
          it 'calls save on parent once' do
            parent
            expect(parent).to receive(:save).once.and_return(true)
            expect(son.save).to be_truthy
          end

          it 'saves son to parent' do
            parent
            expect(son.save).to be_truthy
            parent.reload
            expect(parent.son).to eq son
            expect(parent.emb).to be_nil
          end
        end

        context 'and is persisted' do
          let(:son) { Son.new(something: different, parent: parent) }

          before do
            parent.save!
          end

          it 'changes column values' do
            expect(son.save).to be_truthy
            expect(parent.son_col).to eq('something' => different, '_type' => 'Parent')
            expect(parent.emb_col).to be_nil
          end
        end
      end
    end
  end

  describe 'defined .save!' do
    let(:parent) { Parent.new() }

    context 'when there is no parent' do
      let(:son) { Son.new }

      it 'raises error' do
        expect{ son.save! }.to raise_error(Embedson::NoParentError)
      end
    end

    context 'when there are parents' do
      let(:son) { Son.new(parent: parent, parent_two: parent_two) }

      context 'and save on all returns true' do
        it 'returns true' do
          expect(son.save!).to eq(true)
        end
      end

      context 'and save on one of them fails' do
        before do
          parent_two.save!
          allow(parent_two).to receive(:save!).and_return(false)
        end

        it 'returns false' do
          expect(son.save!).to be_falsy
        end

        it 'does not change any of parents' do
          parent.save!
          expect{ son.save! }.to_not change{ parent.reload.son_col }
          expect(parent_two.reload.son_col).to eq different
        end
      end

      context 'and parent is new record' do
        it 'calls save! on all parents' do
          parent
          expect(parent).to receive(:save!).and_return(true)
          expect(parent_two).to receive(:save!).and_return(true)
          expect(son.save!).to be_truthy
        end

        it 'saves son to parent' do
          parent
          expect(son.save!).to be_truthy
          parent.reload
          expect(parent.son).to eq son
          expect(parent.emb).to be_nil
          expect(parent_two.reload.son).to eq son
        end
      end

      context 'and parent is persisted' do
        let(:son) { Son.new(something: different, parent: parent, parent_two: parent_two) }

        before do
          parent.save!
          parent_two.save!
        end

        it 'changes column values' do
          expect(son.save!).to be_truthy
          parent.reload
          expect(parent.son_col).to eq('something' => different, '_type' => 'Parent')
          expect(parent.emb_col).to be_nil
          expect(parent_two.reload.son_col).to eq('something' => different, '_type' => 'ParentTwo')
        end

        context 'and son is changed' do
          it 'saves changes in both relations' do
            son.save!
            expect {
              son.change = 'new value'
              son.save!
            }.to change { parent.reload.son_col }
             .from('something' => different, '_type' => 'Parent')
             .to('something' => different, 'change' => 'new value', '_type' => 'Parent')
            expect(parent_two.son_col).to eq('something' => different, 'change' => 'new value', '_type' => 'ParentTwo')
          end
        end
      end

      context 'and parent is one from many defined' do
        let(:son) { Son.new(parent: parent) }

        context 'and is new record' do
          it 'calls save! on parent once' do
            parent
            expect(parent).to receive(:save!).once.and_return(true)
            expect(son.save!).to be_truthy
          end

          it 'saves son to parent' do
            parent
            expect(son.save!).to be_truthy
            parent.reload
            expect(parent.son).to eq son
            expect(parent.emb).to be_nil
          end
        end

        context 'and is persisted' do
          let(:son) { Son.new(something: different, parent: parent) }

          before do
            parent.save!
          end

          it 'changes column values' do
            expect(son.save!).to be_truthy
            expect(parent.son_col).to eq('something' => different, '_type' => 'Parent')
            expect(parent.emb_col).to be_nil
          end
        end
      end
    end
  end

  describe 'defined .destroy' do
    context 'when there is parent' do
      let(:son) { Son.new(parent: parent, parent_two: parent_two) }

      context 'and destroy on all returns true' do
        it 'returns true' do
          expect(son.destroy).to eq(true)
        end
      end

      context 'and save! on one of them fails' do
        before do
          parent_two.save!
          allow(parent_two).to receive(:save!).and_return(false)
        end

        it 'returns false' do
          expect(son.destroy).to be_falsy
        end

        it 'does not change any of parents' do
          parent.save!
          expect{ son.destroy }.to_not change{ parent.reload.son_col }
          expect(parent_two.reload.son_col).to eq different
        end
      end

      context 'and is new record' do

        it 'calls save! on all parents' do
          parent
          expect(parent).to receive(:save!).and_return(true)
          expect(parent_two).to receive(:save!).and_return(true)
          expect(son.destroy).to be_truthy
        end

        it 'saves nil to all relations' do
          parent
          expect(son.destroy).to be_truthy
          parent.reload
          expect(parent.son).to be_nil
          expect(parent.reload.son).to be_nil
        end
      end

      context 'and is persisted' do
        let(:son) { Son.new(something: different, parent: parent, parent_two: parent_two) }

        before do
          parent.save!
          parent_two.save!
        end

        it 'changes column values' do
          expect(son.destroy).to be_truthy
          expect(parent.reload.son_col).to be_nil
          expect(parent_two.reload.son_col).to be_nil
        end
      end

      context 'and parent is one from many defined' do
        let(:son) { Son.new(parent: parent) }

        context 'and is new record' do
          it 'calls save! on parent once' do
            parent
            expect(parent).to receive(:save!).once.and_return(true)
            expect(son.save!).to be_truthy
          end

          it 'saves nil to parent' do
            parent
            expect(son.destroy).to be_truthy
            parent.reload
            expect(parent.son).to be_nil
            expect(parent.emb_col).to eq different
          end
        end

        context 'and is persisted' do
          let(:son) { Son.new(something: different, parent: parent) }

          before do
            parent.save!
          end

          it 'changes column values' do
            expect(son.destroy).to be_truthy
            parent.reload
            expect(parent.son_col).to be_nil
            expect(parent.emb_col).to eq different
          end
        end
      end
    end
  end
end
