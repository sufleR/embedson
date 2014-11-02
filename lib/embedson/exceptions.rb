module Embedson
  class ClassTypeError < TypeError
    attr_reader :wrong_name, :correct_name

    def initialize(wrong_name, correct_name)
      @wrong_name, @correct_name = wrong_name, correct_name
      super(build_message)
    end

    def build_message
      "Wrong argument type #{wrong_name} (expected #{correct_name})"
    end
  end

  class NoParentError < StandardError

    def initialize(action, klass_name)
      super("Cannot #{action} embedded #{klass_name} without a parent relation.")
    end
  end

  class NoRelationDefinedError < StandardError
    attr_reader :klass_name, :inverse_name

    def initialize(klass_name, inverse_name)
      @klass_name, @inverse_name = klass_name, inverse_name
      super(build_message)
    end

    def build_message
      "Parent class #{klass_name} has no '#{inverse_name}' method defined or inverse_of option is not set properly."
    end
  end
end
