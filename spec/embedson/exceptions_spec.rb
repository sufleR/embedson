require 'spec_helper'

describe Embedson::ClassTypeError do
  let(:error) { Embedson::ClassTypeError.new('Wrong', 'Correct') }

  it 'raises with correct message' do
    expect(error.message).to eq "Wrong argument type Wrong (expected Correct)"
  end
end

describe Embedson::NoParentError do
  let(:error) { Embedson::NoParentError.new('assign', 'Correct') }

  it 'raises with correct message' do
    expect(error.message).to eq "Cannot assign embedded Correct without a parent relation."
  end
end

describe Embedson::NoParentError do
  let(:error) { Embedson::NoRelationDefinedError.new('Klass', 'embedded=') }

  it 'raises with correct message' do
    expect(error.message).to eq "Parent class Klass has no 'embedded=' method defined or inverse_of option is not set properly."
  end
end
