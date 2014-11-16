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
          klass.class_exec builder, &self.method(meth)
        end
      end

      private

      def methods_embedded
        self.class.private_instance_methods(false).select{ |m| m.to_s.start_with?('embedded_') }
      end

      def embedded_alter_initialize(builder)
        klass.send :alias_method, "#{builder.field_name}_initialize".to_sym, :initialize
        klass.send :private, "#{builder.field_name}_initialize"
      end

      def embedded_initializer(builder)
        klass.send :define_method, "initialize" do |*args|
          attrs = args[0] || {}
          val = attrs.delete(builder.field_name)

          send("#{builder.field_name}_initialize", *args)
          public_send("#{builder.field_name}=", val) if val.present?
        end
      end

      def embedded_writer(builder)
        klass.send :define_method, "#{builder.field_name}=" do |arg|
          send("#{builder.field_name}_verify_arg_klass", arg)

          instance_variable_set(builder.instance_var_name, arg)

          send("#{builder.field_name}_send_to_related", self)
        end
      end

      def embedded_reader(builder)
        klass.send :define_method, builder.field_name do
          instance_variable_get(builder.instance_var_name)
        end
      end

      def embedded_destroy(builder)
        klass.send :define_method, 'destroy' do
          call_in_transaction_for_all_embedding('save!', nil)
        end
      end

      def embedded_save(builder)
        klass.send :define_method, 'save' do
          call_in_transaction_for_all_embedding('save', self)
        end
      end

      def embedded_save!(builder)
        klass.send :define_method, 'save!' do
          raise NoParentError.new('save!', self.class.name) unless any_embedding_present?
          call_in_transaction_for_all_embedding('save!', self)
        end
      end

      def embedded_changed(builder)
        klass.send :define_method, 'embedson_model_changed!' do
          raise NoParentError.new('register change', self.class.name) unless any_embedding_present?

          self.class.embedson_relations.each do |relation|
            send("#{relation}_send_to_related", self) if public_send(relation).present?
          end
          true
        end
      end

      def embedded_send_to_related(builder)
        klass.send :define_method, "#{builder.field_name}_send_to_related" do |arg|
          parent = public_send(builder.field_name)
          return if parent.nil?
          unless parent.respond_to?(builder.inverse_set)
            raise NoRelationDefinedError.new(parent.class, builder.inverse_set)
          end
          parent.public_send(builder.inverse_set, arg)
        end
        klass.send :private, "#{builder.field_name}_send_to_related"
      end

      def embedded_call_in_transaction_for_all_embedding(builder)
        return if klass.methods.include? :call_in_transaction_for_all_embedding
        klass.send :define_method, :call_in_transaction_for_all_embedding do |method, object|
          results = []
          ActiveRecord::Base.transaction do
            self.class.embedson_relations.each do |field_name|
              next if public_send(field_name).nil?
              send("#{field_name}_send_to_related", object)
              save_res = public_send(field_name).send(method)
              results << save_res
              raise ActiveRecord::Rollback unless save_res
            end
          end
          !results.size.zero? && results.all?
        end
      end

      def embedded_any_present?(builder)
        return if klass.methods.include? :any_ebedding_present?
        klass.send :define_method, :any_embedding_present? do
          self.class.embedson_relations.any?{ |r| public_send(r).present? }
        end

        klass.send :private, :any_embedding_present?
      end
    end
  end
end
