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
        methods_for_both.each do |meth|
          klass.class_exec self, &send(meth)
        end
      end

      def embedded
        EmbeddedBuilder.new(self).define
        methods_for_both.each do |meth|
          klass.class_exec self, &send(meth)
        end
      end

      def column_name
        @column_name ||= options.fetch(:column_name, nil) || field_name
      end

      def related_klass_name
        @related_klass_name ||= (options.fetch(:class_name, nil) || field_name).to_s.classify
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

      def methods_for_both
        [:send_self_to_related, :verify_arg_klass]
      end

      def verify_arg_klass
        proc do |builder|
          private

          define_method('verify_arg_klass') do |arg|
            unless arg.nil? || arg.is_a?(builder.related_klass_name.constantize)
              raise ClassTypeError.new(arg.class.name, builder.related_klass_name)
            end
          end
        end
      end

      def send_self_to_related
        proc do |builder|
          private

          define_method('send_self_to_related') do |arg|
            if arg.respond_to?(builder.inverse_set) && arg.public_send(builder.inverse_get) != self
              arg.public_send(builder.inverse_set, self)
            end

          end
        end
      end
    end
  end
end
