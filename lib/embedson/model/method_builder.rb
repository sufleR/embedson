module Embedson
  module Model

    class MethodBuilder

      attr_reader :klass, :field_name, :options

      def initialize(klass, name, options)
        @klass = klass
        @field_name = name
        @options = options
      end

      def embeds
        methods_embeds.each do |meth|
          klass.class_exec self, &send(meth)
        end
      end

      def embedded
        methods_embedded.each do |meth|
          klass.class_exec self, &send(meth)
        end
      end

      def column_name
        @column_name ||= options.fetch(:column_name, nil) || field_name
      end

      def related_klass_name
        @related_klass_name ||= (options.fetch(:class_name, nil) || field_name).to_s.classify
      end

      def inverse_get
        @inverse_get ||= options.fetch(:inverse_of, nil) || klass.name.demodulize.tableize.singularize
      end

      def inverse_set
        "#{inverse_get}="
      end

      private

      def methods_embedded
        self.class.private_instance_methods(false).select{ |m| m.to_s.start_with?('embedded_') }
      end

      def methods_embeds
        self.class.private_instance_methods(false).select{ |m| m.to_s.start_with?('embeds_') }
      end

      def embeds_writer
        proc do |builder|
          define_method("#{builder.field_name}=") do |arg|
            raise ClassTypeError.new(arg.class.name, builder.related_klass_name) unless arg.nil? || arg.is_a?(builder.related_klass_name.constantize)

            if arg.respond_to?(builder.inverse_set) && arg.public_send(builder.inverse_get) != self
              arg.public_send(builder.inverse_set, self)
            end

            instance_variable_set("@#{builder.field_name}", arg)
            write_attribute(builder.column_name, arg.nil? ? arg : arg.to_h)
          end
        end
      end

      def embeds_reader
        proc do |builder|
          define_method(builder.field_name) do
            return if read_attribute(builder.column_name).nil?

            build_related_model if instance_variable_get("@#{builder.field_name}").nil?
            instance_variable_get("@#{builder.field_name}")
          end
        end
      end

      def embeds_build_related_model
        proc do |builder|
          private
          define_method('build_related_model') do
            model = builder.related_klass_name.constantize.new(read_attribute(builder.column_name))
            instance_variable_set("@#{builder.field_name}", model)
            model.public_send(builder.inverse_set, self) if model.respond_to?(builder.inverse_set)
          end
        end
      end

      def embedded_reader
        proc do |builder|
          define_method(builder.field_name) do
            instance_variable_get("@#{builder.field_name}")
          end
        end
      end

      def embedded_writer
        proc do |builder|
          define_method("#{builder.field_name}=") do |arg|
            raise ClassTypeError.new(arg.class.name, builder.related_klass_name) unless arg.nil? || arg.is_a?(builder.related_klass_name.constantize)

            instance_variable_set("@#{builder.field_name}", arg)
            parent = public_send(builder.field_name)

            if parent.respond_to?(builder.inverse_set) && parent.public_send(builder.inverse_get) != self
              parent.public_send(builder.inverse_set, self)
            end
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
            raise "No parent model defined!" unless parent.present?
            parent.public_send(builder.inverse_set, self)
            true
          end
        end
      end
    end
  end
end
