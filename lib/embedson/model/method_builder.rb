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
        EmbedsBuilder.new(self).define
        generate_common
      end

      def embedded
        EmbeddedBuilder.new(self).define
        generate_common
      end

      def hash_method
        @hash_method ||= options.fetch(:hash_method, nil) || :to_h
      end

      def column_name
        @column_name ||= options.fetch(:column_name, nil) || field_name
      end

      def related_klass_name
        @related_klass_name ||= (options.fetch(:class_name, nil) || field_name).to_s.camelize
      end

      def instance_var_name
        @instance_var_name ||= "@#{field_name}"
      end

      def inverse_get
        @inverse_get ||= options.fetch(:inverse_of, nil) || klass.name.demodulize.tableize.singularize
      end

      def inverse_set
        @inverse_set ||= "#{inverse_get}="
      end

      private

      def generate_common
        methods_for_both.each do |meth|
          klass.class_exec self, &self.method(meth)
        end
      end

      def methods_for_both
        [:verify_arg_klass]
      end

      def verify_arg_klass(builder)
        klass.send(:define_method, "#{field_name}_verify_arg_klass") do |arg|
          unless arg.nil? || arg.is_a?(builder.related_klass_name.constantize)
            raise ClassTypeError.new(arg.class.name, builder.related_klass_name)
          end
        end
        klass.send(:private, "#{field_name}_verify_arg_klass")
      end
    end
  end
end
