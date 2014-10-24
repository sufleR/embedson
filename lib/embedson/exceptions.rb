module Embedson
  class ClassTypeError < TypeError
    attr_reader :wrong_name, :correct_name

    def initialize(wrong_name, correct_name)
      @wrong_name, @correct_name = wrong_name, correct_name
      super(build_message)
    end

    def build_message
      "wrong argument type #{wrong_name} (expected #{correct_name})"
    end
  end
end