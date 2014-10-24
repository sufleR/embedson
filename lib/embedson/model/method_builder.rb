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
        klass.class_exec field_name, related_klass_name, column_name, inverse_get, inverse_set, &embeds_writer
        klass.class_exec field_name, related_klass_name, column_name, inverse_set, &embeds_reader
      end

      def embedded
        klass.class_exec field_name, &embedded_reader
        klass.class_exec field_name, related_klass_name, column_name, inverse_get, inverse_set, &embedded_writer
        klass.class_exec field_name, &embedded_save
        klass.class_exec field_name, inverse_set, &embedded_destroy
        klass.class_exec field_name, inverse_set, &embedded_changed
      end

      private

      def embeds_writer
        lambda do |field_name, related_klass_name, column_name, inverse_get, inverse_set|
          define_method("#{field_name}=") do |arg|
            raise ClassTypeError.new(arg.class.name, related_klass_name) unless arg.nil? || arg.is_a?(related_klass_name.constantize)

            if arg.respond_to?(inverse_set) && arg.public_send(inverse_get) != self
              arg.public_send(inverse_set, self)
            end

            instance_variable_set("@#{field_name}", arg)
            write_attribute(column_name, arg.nil? ? arg : arg.to_h)
          end
        end
      end

      def embeds_reader
        lambda do |field_name, related_klass_name, column_name, inverse_set|
          define_method(field_name) do
            return if read_attribute(column_name).nil?

            if instance_variable_get("@#{field_name}").nil?
              model = related_klass_name.constantize.new(read_attribute(column_name))
              instance_variable_set("@#{field_name}", model)
              model.public_send(inverse_set, self) if model.respond_to?(inverse_set)
            end
            instance_variable_get("@#{field_name}")
          end
        end
      end

      def embedded_reader
        lambda do |field_name|
          define_method(field_name) do
            instance_variable_get("@#{field_name}")
          end
        end
      end

      def embedded_writer
        lambda do |field_name, related_klass_name, column_name, inverse_get, inverse_set|
          define_method("#{field_name}=") do |arg|
            raise ClassTypeError.new(arg.class.name, related_klass_name) unless arg.nil? || arg.is_a?(related_klass_name.constantize)

            instance_variable_set("@#{field_name}", arg)
            parent = public_send(field_name)

            if parent.respond_to?(inverse_set) && parent.public_send(inverse_get) != self
              parent.public_send(inverse_set, self)
            end
          end
        end
      end

      def embedded_destroy
        lambda do |field_name, inverse_set|
          define_method('destroy') do
            parent = public_send(field_name)
            return false unless parent.present?
            parent.public_send(inverse_set, nil)
            parent.save!
          end
        end
      end

      def embedded_save
        lambda do |field_name|
          define_method('save') do
            parent = public_send(field_name)
            return false unless parent.present?
            parent.save
          end
        end
      end

      def embedded_changed
        lambda do |field_name, inverse_set|
          define_method('embedson_model_changed!') do
            parent = public_send(field_name)
            raise "No parent model defined!" unless parent.present?
            parent.public_send(inverse_set, self)
            true
          end
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
    end

  end
end
