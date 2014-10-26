require 'spec_helper'

describe Embedson::Model do

  describe '#emdbeds_one' do
    context 'when only relation name is specified' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end

        model do
          extend Embedson::Model

          embeds_one :embedded
        end
      end

      class Embedded < OpenStruct

        def to_h
          { defined: 'in', embedded: true }
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Parent).to respond_to(:embeds_one)
      end

      it 'adds "embedded" method' do
        expect(parent).to respond_to(:embedded)
      end

      it 'adds "embedded=" method' do
        expect(parent).to respond_to("embedded=")
      end

      describe 'defined .embedded= method' do
        it 'assigns value of embedded class' do
          expect {
            parent.embedded = embedded
          }.to change{ parent.embedded }.from(nil).to(embedded)
        end

        context 'when assigning nil' do
          let(:parent) { Parent.new(embedded: embedded) }

          it 'removes assignmnent' do
            parent
            expect {
              parent.embedded = nil
            }.to change { parent.embedded }.from(embedded).to(nil)
          end
        end

        context 'when assigning wrong class' do
          it 'raises ClassTypeError' do
            expect{
              parent.embedded = 'something'
            }.to raise_error(Embedson::ClassTypeError)
          end
        end

        context 'when Parent is persisted' do
          before do
            parent.save!
          end

          it 'marks parent as changed' do
            expect {
              parent.embedded = embedded
            }.to change{ parent.changed? }.from(false).to(true)
          end

          context 'and saved after change' do
            it 'saves Embedded class in column' do
              expect{
                parent.embedded = embedded
                parent.save!
              }.to change { parent.reload.read_attribute(:embedded) }.from(nil).to(embedded.to_h.stringify_keys)
            end
          end
        end
      end

      describe 'defined .embedded method' do
        context 'when value column is null' do
          it 'returns nil' do
            expect(parent.embedded).to be nil
          end
        end

        it 'returns embedded class' do
          parent.embedded = embedded
          expect(parent.embedded).to be_a Embedded
        end

        context 'when there is defined value in column' do
          before do
            parent.embedded = embedded
            parent.save!
          end

          it 'returns embedded class initialized with value from column' do
            expect(parent.reload.embedded).to eq embedded
          end
        end
      end
    end

    context 'when options include column_name' do

      with_model :Parent do
        table do |t|
          t.json :data
        end

        model do
          extend Embedson::Model

          embeds_one :embedded, column_name: :data
        end
      end

      class Embedded < OpenStruct

        def to_h
          { defined: 'in', embedded: true }
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Parent).to respond_to(:embeds_one)
      end

      it 'adds "embedded" method' do
        expect(Parent.new()).to respond_to(:embedded)
      end

      it 'adds "embedded=" method' do
        expect(Parent.new()).to respond_to("embedded=")
      end

      it 'saves embedded class to data column' do
        expect {
          parent.embedded = embedded
          parent.save!
        }.to change{ parent.read_attribute(:data) }.from(nil).to(embedded.to_h.stringify_keys)
      end
    end

    context 'when options include inverse_of' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end

        model do
          extend Embedson::Model

          embeds_one :embedded, inverse_of: :parent_m
        end
      end

      class Embedded < OpenStruct
        extend Embedson::Model

        embedded_in :parent_m, class_name: 'Parent'

        def to_h
          { defined: 'in', embedded: true }
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Parent).to respond_to(:embeds_one)
      end

      it 'adds "embedded" method' do
        expect(Parent.new()).to respond_to(:embedded)
      end

      it 'adds "embedded=" method' do
        expect(Parent.new()).to respond_to("embedded=")
      end

      it 'assigns self to parent_m in embedded class' do
        parent.embedded = embedded
        expect(parent.embedded.parent_m).to eq parent
      end
    end

    context 'when options include class_name' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end

        model do
          extend Embedson::Model

          embeds_one :emb, class_name: 'Embedded', column_name: :embedded
        end
      end

      class Embedded < OpenStruct
        extend Embedson::Model

        embedded_in :parent

        def to_h
          { defined: 'in', embedded: true }
        end
      end

      let(:parent) { Parent.new(embedded: { some: 'thing' }) }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Parent).to respond_to(:embeds_one)
      end

      it 'adds "emb" method' do
        expect(Parent.new()).to respond_to(:emb)
      end

      it 'adds "emb=" method' do
        expect(Parent.new()).to respond_to("emb=")
      end

      it 'assigns self to parent_m in embedded class' do
        expect(parent.emb.some).to eq 'thing'
      end
    end
  end
end
