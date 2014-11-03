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

      def embedded_alter_initialize
        proc do |builder|
          private

          alias_method "#{builder.field_name}_initialize".to_sym, :initialize
        end
      end

      def embedded_initializer
        proc do |builder|
          define_method("initialize") do |*args|
            attrs = args[0] || {}
            val = attrs.delete(builder.field_name)

            send("#{builder.field_name}_initialize", *args)
            public_send("#{builder.field_name}=", val) if val.present?
          end
        end
      end

      def embedded_writer
        proc do |builder|
          define_method("#{builder.field_name}=") do |arg|
            send("#{builder.field_name}_verify_arg_klass", arg)

            instance_variable_set(builder.instance_var_name, arg)

            send("#{builder.field_name}_send_to_related", self)
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

      def embedded_alter_destroy
        proc do |builder|
          if self.instance_methods(false).include?(:destroy)
            alias_method "#{builder.field_name}_destroy".to_sym, :destroy
          end
        end
      end

      def embedded_destroy
        proc do |builder|
          define_method('destroy') do
            parent = public_send(builder.field_name)
            return false unless parent.present?

            send("#{builder.field_name}_send_to_related", nil)
            parent.save!
            if respond_to?("#{builder.field_name}_destroy")
              send("#{builder.field_name}_destroy")
            end
          end
        end
      end

      def embedded_alter_save
        proc do |builder|
          if self.instance_methods(false).include?(:save)
            alias_method "#{builder.field_name}_save".to_sym, :save
          end
        end
      end

      def embedded_save
        proc do |builder|
          define_method('save') do
            parent = public_send(builder.field_name)
            return false unless parent.present?

            send("#{builder.field_name}_send_to_related", self)
            parent.save
            if respond_to?("#{builder.field_name}_save")
              send("#{builder.field_name}_save")
            end
          end
        end
      end

      def embedded_alter_save!
        proc do |builder|
          if self.instance_methods(false).include?(:save!)
            alias_method "#{builder.field_name}_save!".to_sym, :save!
          end
        end
      end

      def embedded_save!
        proc do |builder|
          define_method('save!') do
            parent = public_send(builder.field_name)
            raise NoParentError.new('save!', self.class.name) unless parent.present?

            send("#{builder.field_name}_send_to_related", self)
            parent.save!
            if respond_to?("#{builder.field_name}_save!")
              send("#{builder.field_name}_save!")
            end
          end
        end
      end

      def embedded_changed
        proc do |builder|
          define_method('embedson_model_changed!') do
            parent = public_send(builder.field_name)
            raise NoParentError.new('register change', self.class.name) unless parent.present?

            send("#{builder.field_name}_send_to_related", self)
            true
          end
        end
      end

      def embedded_send_to_related
        proc do |builder|
          private

          define_method("#{builder.field_name}_send_to_related") do |arg|
            parent = public_send(builder.field_name)
            return if parent.nil?
            raise NoRelationDefinedError.new(parent.class, builder.inverse_set) unless parent.respond_to?(builder.inverse_set)
            parent.public_send(builder.inverse_set, arg)
          end
        end
      end
    end
  end
end
