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
          parents = self.class.embedson_relations.map{ |r| public_send(r) }
          return false unless parents.any?

          parents.each_with_index do |parent, i|
            next if parent.nil?
            send("#{self.class.embedson_relations[i]}_send_to_related", nil)
            parent.save!
          end
        end
      end

      def embedded_save(builder)
        klass.send :define_method, 'save' do
          parents = self.class.embedson_relations.map{ |r| public_send(r) }
          return false unless parents.any?

          parents.each_with_index do |parent, i|
            next if parent.nil?
            send("#{self.class.embedson_relations[i]}_send_to_related", self)
            parent.save
          end
        end
      end

      def embedded_save!(builder)
        klass.send :define_method, 'save!' do
          parents = self.class.embedson_relations.map{ |r| public_send(r) }
          raise NoParentError.new('save!', self.class.name) unless parents.any?

          parents.each_with_index do |parent, i|
            next if parent.nil?
            send("#{self.class.embedson_relations[i]}_send_to_related", self)
            parent.save!
          end
        end
      end

      def embedded_changed(builder)
        klass.send :define_method, 'embedson_model_changed!' do
          parents = self.class.embedson_relations.map{ |r| public_send(r) }
          unless parents.any?
            raise NoParentError.new('register change', self.class.name)
          end

          parents.each_with_index do |parent, i|
            send("#{self.class.embedson_relations[i]}_send_to_related", self)
          end
          true
        end
      end

      def embedded_send_to_related(builder)
        klass.send :define_method, "#{builder.field_name}_send_to_related" do |arg|
          parent = public_send(builder.field_name)
          return if parent.nil?
          raise NoRelationDefinedError.new(parent.class, builder.inverse_set) unless parent.respond_to?(builder.inverse_set)
          parent.public_send(builder.inverse_set, arg)
        end
        klass.send :private, "#{builder.field_name}_send_to_related"
      end
    end
  end
end
