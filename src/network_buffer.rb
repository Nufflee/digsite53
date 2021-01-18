class NetworkBuffer
  attr_reader :buffer
  @current_index

  def initialize(buffer = "")
    @buffer = buffer
    @current_index = 0
  end

  def read_u8!(count = 1)
    return read!(count, "C", 1)
  end

  def read_u16!(count = 1)
    return read!(count, "n", 2)
  end

  def read_string!(length)
    check_out_of_bounds(@current_index + length)

    result = @buffer[@current_index, length]

    @current_index += length

    return result
  end

  def write8!(values)
    write!(values, "C", 1)
  end

  def write16!(values)
    write!(values, "n", 2)
  end

  def write32!(values)
    write!(values, "N", 4)
  end

  def write_string!(string)
    @buffer += string
  end

  def get_remaining()
    return @buffer[@current_index..@buffer.length]
  end

  private def check_out_of_bounds(index)
    raise "Buffer index #{index} out of range (buffer length = #{@buffer.length})" unless index < @buffer.length
  end

  private def read!(count, format_specifier, size)
    check_out_of_bounds(@current_index + size * count - 1)

    values = count.times.map do
      unpacked = @buffer[@current_index, size].unpack(format_specifier)[0]

      @current_index += size

      unpacked
    end

    if count == 1
      return values[0]
    end

    return values
  end

  private def write!(values, format_specifier, size)
    if !values.kind_of?(Array)
      values = [values]
    end

    @current_index += values.length * size

    @buffer += values.map { |value| [value].pack(format_specifier) }.join
  end
end
