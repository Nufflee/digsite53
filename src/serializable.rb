require_relative "./network_buffer"
require_relative "./utils"

class Serializable
  MAP_VARIABLE_NAME = :@@__serializationMap__

  SimpleSymbol = Struct.new(:type, :type_args)
  ClassSymbol = Struct.new(:klass)
  CustomSymbol = Struct.new(:serialize_proc, :deserialize_proc)

  def self.attr_serialize(*args)
    unless class_variable_defined?(MAP_VARIABLE_NAME)
      class_variable_set(MAP_VARIABLE_NAME, {})
    end

    raise "attr_serialize expected at least 2 arguments but #{args.length} were given" unless args.length >= 2

    if args[0] == :string
      raise "No length type provided for string serialization" unless args.length >= 3

      types = [args[0], args[1]]
      fields = args[2..]

      check_type(types[1])

      symbol = SimpleSymbol.new(types[0], [types[1]])
    else
      type = args[0]
      fields = args[1..]

      symbol = check_type(type) || SimpleSymbol.new(type)
    end

    fields.each do |variable|
      class_variable_get(MAP_VARIABLE_NAME)[variable] = symbol

      instance_variable_set(symbol_to_instance_field(variable), nil)
    end

    return *fields
  end

  private_class_method def self.check_type(type)
    if !NetworkBuffer.valid_writable_type?(type) && !NetworkBuffer.valid_readable_type?(type)
      raise TypeError, "'#{type}' doesn't exist" unless Module.const_defined? type

      klass = Module.const_get(type)

      raise TypeError, "'#{type}' is not a class and hence not serializable" unless klass.is_a?(Class)
      raise TypeError, "'#{type}' does not inheirt from 'Serializable'" unless klass.ancestors.include? Serializable

      return ClassSymbol.new(klass)
    end

    raise "Type '#{type}' is not serializable" unless NetworkBuffer.valid_writable_type?(type)
    raise "Type '#{type}' is not deserializable" unless NetworkBuffer.valid_readable_type?(type)

    return nil
  end

  def self.attr_serialize_custom(serialize_proc, deserialize_proc, *fields)
    unless class_variable_defined?(MAP_VARIABLE_NAME)
      class_variable_set(MAP_VARIABLE_NAME, {})
    end

    raise "attr_serialize_custom expected at least one field but none were given" if fields.empty?

    fields.each do |variable|
      class_variable_get(MAP_VARIABLE_NAME)[variable] = CustomSymbol.new(serialize_proc, deserialize_proc)
    end
  end

  def self.generate_attr_wrappers(attr)
    %w[accessor reader writer].each do |wrapped|
      define_singleton_method("#{attr}_#{wrapped}") do |*args|
        send("attr_#{wrapped}", *send(attr, *args))
      end
    end
  end

  generate_attr_wrappers(:attr_serialize)
  generate_attr_wrappers(:attr_serialize_custom)

  def serialize(buffer = nil)
    if buffer.nil?
      buffer = NetworkBuffer.new
    end

    self.class.class_variable_get(MAP_VARIABLE_NAME).each do |variable, symbol|
      value = instance_variable_get(symbol_to_instance_field(variable))

      if symbol.is_a?(CustomSymbol)
        send(symbol.serialize_proc, buffer, value)
      elsif symbol.is_a?(ClassSymbol)
        value.serialize(buffer)
      elsif symbol.type == :string
        buffer.write_string!(value, symbol.type_args[0])
      else
        buffer.write!(symbol.type, value)
      end
    end

    buffer
  end

  def self.deserialize(buffer)
    instance = new

    class_variable_get(MAP_VARIABLE_NAME).each do |variable, symbol|
      pp symbol.is_a?(ClassSymbol)

      value = if symbol.is_a?(CustomSymbol)
                send(symbol.deserialize_proc, buffer)
              elsif symbol.is_a?(ClassSymbol)
                symbol.klass.deserialize(buffer)
              elsif symbol.type == :string
                buffer.read_string_and_length!(symbol.type_args[0])
              else
                buffer.read!(symbol.type)
              end

      instance.instance_variable_set("@#{variable}", value)
    end

    instance
  end
end
