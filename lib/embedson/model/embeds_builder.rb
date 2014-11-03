module Embedson
  module Model
    class EmbedsBuilder
      attr_reader :builder, :klass

      def initialize(builder)
        @builder = builder
        @klass = builder.klass
      end

      def define
        methods_embeds.each do |meth|
          klass.class_exec builder, &send(meth)
        end
      end

      private

      def methods_embeds
        [:writer, :reader, :related_model, :build_related_model, :send_to_related]
      end

      def writer
        proc do |builder|
          define_method("#{builder.field_name}=") do |arg|
            send("#{builder.field_name}_verify_arg_klass", arg)
            send("#{builder.field_name}_send_to_related", arg)

            instance_variable_set(builder.instance_var_name, arg)
            val = arg.nil? ? arg : arg.to_h.stringify_keys
            unless val == read_attribute(builder.column_name)
              write_attribute(builder.column_name, val)
            end
          end
        end
      end

      def reader
        proc do |builder|
          define_method(builder.field_name) do
            return if read_attribute(builder.column_name).nil?

            send("#{builder.field_name}_build_related_model") if instance_variable_get(builder.instance_var_name).nil?
            instance_variable_get(builder.instance_var_name)
          end
        end
      end

      def related_model
        proc do |builder|
          private

          define_method("#{builder.field_name}_related_model") do
            builder.related_klass_name.constantize.new(read_attribute(builder.column_name))
          end
        end
      end

      def build_related_model
        proc do |builder|
          private

          define_method("#{builder.field_name}_build_related_model") do
            related_model = send("#{builder.field_name}_related_model")
            instance_variable_set(builder.instance_var_name, related_model)
            if related_model.respond_to?(builder.inverse_set)
              related_model.public_send(builder.inverse_set, self)
            end
          end
        end
      end

      def send_to_related
        proc do |builder|
          private

          define_method("#{builder.field_name}_send_to_related") do |arg|
            if arg.respond_to?(builder.inverse_set) && arg.public_send(builder.inverse_get) != self
              arg.public_send(builder.inverse_set, self)
            end
          end
        end
      end
    end
  end
end
