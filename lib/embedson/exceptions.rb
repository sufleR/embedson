module Embedson
  class ClassTypeError < TypeError

    def initialize(wrong_name, correct_name)
      super("Wrong argument type #{wrong_name} (expected #{correct_name})")
    end
  end

  class NoParentError < StandardError

    def initialize(action, klass_name)
      super("Cannot #{action} embedded #{klass_name} without a parent relation.")
    end
  end

  class NoRelationDefinedError < StandardError

    def initialize(klass_name, inverse_name)
      super("Parent class #{klass_name} has no '#{inverse_name}' method defined or inverse_of option is not set properly.")
    end
  end
end
