module Embedson::Model

  def embeds_one(name, options = {})
    column_name = options.fetch(:column_name, nil) || name
    klass_name = (options.fetch(:class_name, nil) || name).to_s.classify
    inverse_get = options.fetch(:inverse_of, nil) || self.name.downcase
    inverse_set = "#{inverse_get}="

    define_method("#{name}=") do |arg|
      raise TypeError, "wrong argument type #{arg.class.name} (expected #{klass_name})" unless arg.nil? || arg.is_a?(klass_name.constantize)

      if arg.respond_to?(inverse_set) && arg.public_send(inverse_get) != self
        arg.public_send(inverse_set, self)
      end

      instance_variable_set("@#{name}", arg)
      write_attribute(column_name, arg.nil? ? arg : arg.to_h)
    end

    define_method(name) do
      return if read_attribute(column_name).nil?

      if instance_variable_get("@#{name}").nil?
        model = klass_name.constantize.new(read_attribute(column_name))
        instance_variable_set("@#{name}", model)
        model.public_send(inverse_set, self) if model.respond_to?(inverse_set)
      end
      instance_variable_get("@#{name}")
    end
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
