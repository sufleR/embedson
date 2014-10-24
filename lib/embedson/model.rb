module Embedson
  module Model

    def embeds_one(name, options = {})
      MethodBuilder.new(self, name, options).embeds
    end

    def embedded_in(name, options = {})
      klass_name = (options.fetch(:class_name, nil) || name).to_s.classify
      inverse_get = options.fetch(:inverse_of, nil) || self.name.demodulize.tableize.singularize
      inverse_set = "#{inverse_get}="

      define_method(name) do
        instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |arg|
        raise TypeError, "wrong argument type #{arg.class.name} (expected #{klass_name})" unless arg.nil? || arg.is_a?(klass_name.constantize)

        instance_variable_set("@#{name}", arg)
        parent = public_send(name)

        if parent.respond_to?(inverse_set) && parent.public_send(inverse_get) != self
          parent.public_send(inverse_set, self)
        end
      end

      define_method('destroy') do
        parent = public_send(name)
        return false unless parent.present?
        parent.public_send(inverse_set, nil)
        parent.save!
      end

      define_method('save') do
        parent = public_send(name)
        return false unless parent.present?
        parent.save
      end

      define_method('save!') do
        parent = public_send(name)
        raise "No parent model defined!" unless parent.present?
        parent.save!
      end

      define_method('embedson_model_changed!') do
        parent = public_send(name)
        raise "No parent model defined!" unless parent.present?
        parent.public_send(inverse_set, self)
        true
      end
    end
  end
end
