class Integer
  def slice_bits(range_or_start, length = nil)
    if length
      start = range_or_start
    else
      range = range_or_start
      start = range.begin
      length = range.count
    end

    mask = 2**length - 1

    self >> start & mask
  end

  def get_bit(nth)
    slice_bits(nth, 1)
  end
end

class Addrinfo
  def ip_to_s
    if ip?
      result = ip_address.to_s
    else
      raise ArgumentError, "Cannot stringify an `addrinfo` without an IP address"
    end

    if ip_port != 0
      result += ":#{ip_port}"
    end

    result
  end
end

class Module
  def generate_constructor(*args)
    if args.empty? || args.nil?
      args = instance_variables.map { |variable| variable.to_s.gsub("@", "") }
    end

    class_eval <<~KOD, __FILE__, __LINE__ + 1
      def initialize(*args)
        raise ArgumentError.new "wrong number of arguments (given " + args.length.to_s + ", expected 0 or #{args.length})" unless args.length.zero? || args.length == #{args.length}

        if args.length > 0
          #{args.each_with_index.map { |arg, i| "@#{arg} = args[#{i}]" }.join("\n")}
        end
      end
    KOD
  end
end
