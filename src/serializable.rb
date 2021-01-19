class Serializable
  MAP_VARIABLE_NAME = :@@__serializationMap__

  def self.attr_serialize(*args)
    if !class_variable_defined?(MAP_VARIABLE_NAME)
      class_variable_set(MAP_VARIABLE_NAME, {})
    end

    check_type = proc { |type|
      raise "Type '#{type}' is not serializable" unless NetworkBuffer.is_valid_writable_type(type)
      raise "Type '#{type}' is not deserializable" unless NetworkBuffer.is_valid_readable_type(type)
    }

    raise "attr_serialize expected at least 3 arguments but #{args.length} were given" unless args.length >= 2

    if args[0] == :string
      raise "No length type provided for string serialization" unless args.length >= 3

      types = [args[0], args[1]]
      variables = args[2..]

      check_type.(types[1])
    else
      types = args[0]
      variables = args[1..]

      check_type.(types)
    end

    variables.each { |variable|
      class_variable_get(MAP_VARIABLE_NAME)[variable] = types
    }

    return *variables
  end

  def self.attr_serialize_accessor(*args)
    attr_accessor *attr_serialize(*args)
  end

  def self.attr_serialize_reader(*args)
    attr_reader *attr_serialize(*args)
  end

  def self.attr_serialize_writer(*args)
    attr_writer *attr_serialize(*args)
  end

  def serialize(buffer = nil)
    if buffer == nil
      buffer = NetworkBuffer.new
    end

    self.class.class_variable_get(MAP_VARIABLE_NAME).each { |variable, type|
      value = instance_variable_get("@#{variable}")

      if type[0] == :string
        buffer.write_string!(value, type[1])
      else
        buffer.write!(type, value)
      end
    }

    buffer.reset_index!()

    return buffer
  end

  def self.deserialize(buffer)
    instance = self.new

    self.class_variable_get(MAP_VARIABLE_NAME).each { |variable, type|
      value = if type[0] == :string
          buffer.read_string_and_length!(type[1])
        else
          buffer.read!(type)
        end

      instance.instance_variable_set("@#{variable}", value)
    }

    buffer.reset_index!()

    instance
  end
end
