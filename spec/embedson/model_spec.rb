require 'spec_helper'

describe Embedson::Model do

  describe '#emdbeds_one' do
    context 'when only relation name is specified' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end

        model do
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

  describe '#embedded_in' do
    context 'when only relation name is specified' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end

        model do
          embeds_one :embedded
        end
      end

      class Embedded < OpenStruct
        extend Embedson::Model

        embedded_in :parent

        def change=(arg)
          @change = arg
        end

        def to_h
          h = { defined: 'in', embedded: true }
          h.merge!(change: @change) if @change.present?
          h
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Embedded).to respond_to(:embedded_in)
      end

      it 'adds "parent" method' do
        expect(embedded).to respond_to(:parent)
      end

      it 'adds "parent=" method' do
        expect(embedded).to respond_to("parent=")
      end

      describe 'defined .parent= method' do
        it 'assigns value of embeding class' do
          expect {
            embedded.parent = parent
          }.to change{ embedded.parent }.from(nil).to(parent)
        end

        context 'when assigning nil' do
          let(:embedded) { Embedded.new(parent: parent) }

          it 'removes assignmnent' do
            parent
            expect {
              embedded.parent = nil
            }.to change { embedded.parent }.from(parent).to(nil)
          end
        end

        context 'when assigning wrong class' do
          it 'raises ClassTypeError' do
            expect{
              embedded.parent = 'something'
            }.to raise_error(Embedson::ClassTypeError)
          end
        end

        context 'when parent is persisted' do
          before do
            parent.save!
          end

          it 'marks parent as changed' do
            expect {
              embedded.parent = parent
            }.to change{ parent.changed? }.from(false).to(true)
          end

          context 'and saved after change' do
            it 'saves Embedded class in column' do
              expect{
                embedded.parent = parent
                parent.save!
              }.to change { parent.reload.read_attribute(:embedded) }.from(nil).to(embedded.to_h.stringify_keys)
            end
          end
        end
      end

      describe 'defined .save method' do

        context 'when there is parent' do
          let(:embedded) { Embedded.new(parent: parent) }

          it 'calls .save on parent' do
            expect(parent).to receive(:save)
            embedded.save
          end

          it 'saves to_h result in parent column' do
            parent.save!
            expect {
              embedded.save
            }.to change { parent.reload.read_attribute(:embedded) }.from(nil).to({ "defined" => "in", "embedded" => true })
          end
        end

        context 'when there is no parent' do
          let(:embedded) { Embedded.new }

          it 'returns false' do
            expect(embedded.save).to eq(false)
          end
        end
      end

      describe 'defined .save! method' do

        context 'when there is parent' do
          let(:embedded) { Embedded.new(parent: parent) }

          it 'calls .save on parent' do
            expect(parent).to receive(:save!)
            embedded.save!
          end

          it 'saves to_h result in parent column' do
            parent.save!
            expect {
              embedded.save!
            }.to change { parent.reload.read_attribute(:embedded) }.from(nil).to({ "defined" => "in", "embedded" => true })
          end
        end

        context 'when there is no parent' do
          it 'raises argument error' do
            expect { embedded.save! }.to raise_error(Embedson::NoParentError)
          end
        end
      end

      describe 'defined .destroy method' do

        context 'when there is parent' do
          let(:embedded) { Embedded.new(parent: parent) }

          it 'calls .save! on parent' do
            expect(parent).to receive(:save!)
            embedded.destroy
          end

          it 'saves nil in parent column' do
            embedded.save!
            expect {
              embedded.destroy
            }.to change { parent.reload.read_attribute(:embedded) }.from({ "defined" => "in", "embedded" => true }).to(nil)
          end
        end

        context 'when there is no parent' do
          let(:embedded) { Embedded.new }

          it 'returns false' do
            expect(embedded.destroy).to eq(false)
          end
        end
      end

      describe 'defined .embedson_model_changed! method' do

        context 'when there is parent' do
          let(:embedded) { Embedded.new(parent: parent) }

          it 'returns true' do
            expect(embedded.embedson_model_changed!).to eq(true)
          end

          it 'assigns new value to parent' do
            embedded.change = 'registered'
            expect {
              embedded.embedson_model_changed!
            }.to change { parent.read_attribute(:embedded) }.from({ "defined" => "in", "embedded" => true }).to({ "defined" => "in", "embedded" => true, 'change' => 'registered' })
          end
        end

        context 'when there is no parent' do
          it 'raises argument error' do
            expect { embedded.embedson_model_changed! }.to raise_error(Embedson::NoParentError)
          end
        end
      end
    end

    context 'when options include inverse_of' do

      with_model :Parent do
        table do |t|
          t.json :emb
        end

        model do
          embeds_one :emb, class_name: Embedded
        end
      end

      with_model :Embedded do
        model do
          embedded_in :parent, inverse_of: :emb

          def to_h
            { defined: 'in', embedded: true }
          end
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Embedded).to respond_to(:embedded_in)
      end

      it 'adds "parent" method' do
        expect(embedded).to respond_to(:parent)
      end

      it 'adds "parent=" method' do
        expect(embedded).to respond_to("parent=")
      end

      it 'assigns self to inverse_of value in parent class' do
        embedded.parent = parent
        expect(embedded.parent.emb).to eq embedded
      end
    end

    context 'when options include class_name' do

      with_model :Parented do
        table do |t|
          t.json :embedded
        end

        model do
          embeds_one :embedded
        end
      end

      with_model :Embedded do
        model do
          embedded_in :parent, class_name: Parented

          def to_h
            { defined: 'in', embedded: true }
          end
        end
      end

      let(:parent) { Parented.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Embedded).to respond_to(:embedded_in)
      end

      it 'adds "parent" method' do
        expect(embedded).to respond_to(:parent)
      end

      it 'adds "parent=" method' do
        expect(embedded).to respond_to("parent=")
      end

      describe 'defined .parent method' do
        let(:embedded) { Embedded.new(parent: parent) }

        it 'returns object of Parented class' do
          expect(embedded.parent).to be_a(Parented)
        end
      end
    end

    context 'when parent model does not have defined embeds_one' do

      with_model :Parent do
        table do |t|
          t.json :embedded
        end
      end

      with_model :Embedded do
        model do
          embedded_in :parent

          def to_h
            { defined: 'in', embedded: true }
          end
        end
      end

      let(:parent) { Parent.new() }
      let(:embedded) { Embedded.new() }

      it 'adds "embeds_one" method' do
        expect(Embedded).to respond_to(:embedded_in)
      end

      it 'adds "parent" method' do
        expect(embedded).to respond_to(:parent)
      end

      it 'adds "parent=" method' do
        expect(embedded).to respond_to("parent=")
      end

      describe 'defined .save method' do
        let(:embedded) { Embedded.new(parent: parent) }

        it 'saves parent but not changes embedded column' do
          parent.save!
          expect {
            embedded.save!
          }.not_to change { parent.reload.embedded }.from(nil)
        end
      end
    end
  end
end
