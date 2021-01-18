class Fixnum
  def slice_bits(range_or_start, length = nil)
    if length
      start = range_or_start
    else
      range = range_or_start
      start = range.begin
      length = range.count
    end

    mask = 2 ** length - 1

    self >> start & mask
  end

  def get_bit(n)
    self.slice_bits(n, 1)
  end
end

class Addrinfo
  def ip_to_s()
    if self.ip?
      result = "#{self.ip_address}"
    else
      raise ArgumentError.new "Cannot stringify an `addrinfo` without an IP address"
    end
  
    if self.ip_port != 0
      result += ":#{self.ip_port}"
    end
  
    result
  end
end