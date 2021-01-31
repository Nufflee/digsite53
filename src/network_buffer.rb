# NetworkBuffer is a stateful (meaning it knows where it left off after every read/write) big-endian buffer used for network communications.
# It should be able to write and read basic types such as u8, i16, u32 etc.
# TODO: NetworkBuffer class has too much unrelated functionality
class NetworkBuffer
  attr_reader :buffer

  def initialize(buffer = "")
    @buffer = buffer
    @current_index = 0
  end

  def read!(type, count = 1)
    return read_impl!(count, *self.class.send(:get_readable_type_specifier, type))
  end

  def read_u8!(count = 1)
    return read_impl!(count, "C", 1)
  end

  def read_u16!(count = 1)
    return read_impl!(count, "n", 2)
  end

  def read_string!(length)
    check_out_of_bounds(@current_index + length - 1)

    result = @buffer[@current_index, length]

    @current_index += length

    return result
  end

  def read_string_and_length!(length_type)
    check_out_of_bounds(@current_index + 1)

    return read_string!(read!(length_type))
  end

  def write!(type, values)
    write_impl!(values, type)
  end

  def write8!(values)
    write_impl!(values, :u8)
  end

  def write16!(values)
    write_impl!(values, :u16)
  end

  def write32!(values)
    write_impl!(values, :u32)
  end

  def write_string!(string, length_type = nil)
    unless length_type.nil?
      write!(length_type, string.length)
    end

    @buffer += string
  end

  def reset_index!
    @current_index = 0
  end

  def remaining
    return @buffer[@current_index..@buffer.length]
  end

  def self.serialize(type, values)
    unless values.is_a?(Array)
      values = [values]
    end

    pp type

    return values.map { |value| [value].pack(get_readable_type_specifier(type)[0]) }.join
  end

  def self.valid_readable_type?(type)
    return !get_readable_type_specifier(type).nil?
  end

  def self.valid_writable_type?(type)
    return !get_writable_type_specifier(type).nil?
  end

  private_class_method def self.get_readable_type_specifier(type)
    case type
    when :u8
      return ["C", 1]
    when :u16
      return ["n", 2]
    when :u32
      return ["N", 4]
    else
      return nil
    end
  end

  private_class_method def self.get_writable_type_specifier(type)
    case type
    when :u8, :i8
      return ["C", 1]
    when :u16, :i16
      return ["n", 2]
    when :u32, :i32
      return ["N", 4]
    else
      return nil
    end
  end

  private def check_out_of_bounds(index)
    raise "Buffer index #{index} out of range (buffer length = #{@buffer.length})" unless index < @buffer.length
  end

  # TODO: read_impl! should take in a type instead of a format specifier
  private def read_impl!(count, format_specifier, size)
    check_out_of_bounds(@current_index + size * count - 1)

    values = count.times.map do
      unpacked = @buffer[@current_index, size].unpack1(format_specifier)

      @current_index += size

      unpacked
    end

    if count == 1
      return values[0]
    end

    return values
  end

  private def write_impl!(values, type)
    unless values.is_a?(Array)
      values = [values]
    end

    serialized = self.class.serialize(type, values)
    @current_index += serialized.length

    @buffer += serialized
  end
end
