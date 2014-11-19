module Embedson
  # Public: Defines embeds_one and embedded_in methods.
  #
  # Examples
  #
  #   class Emb
  #     extend Embedson::Model
  #   end
  module Model

    # Public: Creates methods to manage embedded class.
    #
    # name - Name of of relation.
    # options - The Hash options used to define custom column name, class name
    #           and field name in embedded class (default: {}):
    #           :class_name - Name of class which will be ebedded.
    #           :column_name - Name of column where Hash representation will be stored.
    #           :inverse_of - Name of field where related class will store current object.
    #           :hash_method - Method name which returns hash representation os saved object. Default :to_h
    #
    # Examples
    #
    #   embeds_one :virt, class_name: Virt, column_name: :data, inverse_of: :parent
    #
    #   embeds_one :virt
    #
    # Returns nothing
    def embeds_one(name, options = {})
      MethodBuilder.new(self, name, options).embeds
    end

    # Public: Creates methods to manage parent class.
    #
    # name - Name of relation where parent object will be stored.
    # options - The hash options used to define custom class name and field name
    #           in parent class (default: {}):
    #           :class_name - Name of class where current object will be embedded.
    #           :inverse_of - Name of field where parent class will keep current object.
    #
    # Examples
    #
    #   embedded_in :parent, class_name: Test, inverse_of: :virt
    #
    #   embedded_in :parent
    #
    # Returns nothing
    def embedded_in(name, options = {})
      @embedson_relations ||= []
      @embedson_relations << name
      MethodBuilder.new(self, name, options).embedded
    end

    def self.extended(mod)
      attr_reader :embedson_relations
    end
  end
end

ActiveRecord::Base.send :extend, Embedson::Model
