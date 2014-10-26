module Embedson
  module Model
    class EmbeddedBuilder
      attr_reader :builder, :klass

      def initialize(builder)
        @builder = builder
        @klass = builder.klass
      end

      def define
        methods_embedded.each do |meth|
          klass.class_exec builder, &send(meth)
        end
      end

      private

      def methods_embedded
        self.class.private_instance_methods(false).select{ |m| m.to_s.start_with?('embedded_') }
      end

      def embedded_initializer
        proc do |builder|
          define_method("initialize") do |*args|
            attrs = args[0]
            attrs ||= {}
            public_send("#{builder.field_name}=", attrs.fetch(builder.field_name, nil))
            super(*args)
          end
        end
      end

      def embedded_writer
        proc do |builder|
          define_method("#{builder.field_name}=") do |arg|
            verify_arg_klass(arg)

            instance_variable_set(builder.instance_var_name, arg)
            parent = public_send(builder.field_name)

            send_self_to_related(parent)
          end
        end
      end

      def embedded_reader
        proc do |builder|
          define_method(builder.field_name) do
            instance_variable_get(builder.instance_var_name)
          end
        end
      end

      def embedded_destroy
        proc do |builder|
          define_method('destroy') do
            parent = public_send(builder.field_name)
            return false unless parent.present?
            parent.public_send(builder.inverse_set, nil)
            parent.save!
          end
        end
      end

      def embedded_save
        proc do |builder|
          define_method('save') do
            parent = public_send(builder.field_name)
            return false unless parent.present?
            parent.save
          end
        end
      end

      def embedded_changed
        proc do |builder|
          define_method('embedson_model_changed!') do
            parent = public_send(builder.field_name)
            raise NoParentError.new('register change', self.class.name) unless parent.present?
            parent.public_send(builder.inverse_set, self)
            true
          end
        end
      end
    end
  end
end
