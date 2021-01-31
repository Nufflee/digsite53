require_relative "./dns_header"
require_relative "./serializable"

class DNSQuestion < Serializable
  attr_serialize_reader :DNSHeader, :header

  attr_serialize_custom_reader :serialize_labels, :deserialize_labels, :labels

  attr_serialize :u16, :record_type
  attr_serialize :u16, :record_class

  generate_constructor

  def record_type
    DNS_RECORD_TYPES[@record_type]
  end

  def record_class
    DNS_RECORD_CLASSES[@record_class]
  end

  private def serialize_labels(buffer, values)
    values.each { |value| buffer.write_string!(value, :u8) }
    buffer.write8!(0)
  end

  private_class_method def self.deserialize_labels(buffer)
    pp buffer

    labels = []

    loop do
      length = buffer.read_u8!

      break if length.zero?

      labels << buffer.read_string!(length)
    end

    labels
  end
end
