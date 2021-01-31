require_relative "./network_buffer"
require_relative "./serializable"
require_relative "./dns_header"

class DNSAnswer < Serializable
  attr_serialize :DNSHeader, :header

  attr_serialize_custom_reader :serialize_labels, :deserialize_labels, :labels

  attr_serialize :u16, :record_type
  attr_serialize :u16, :record_class
  attr_serialize :u32, :ttl

  # TODO: rdata will still be a string when deserialized, as opposed to a byte array
  attr_serialize :string, :u16, :rdata

  def initialize(header, labels, record_type, record_class, ttl, rdata)
    @header = header
    @labels = labels
    @record_type = record_type
    @record_class = record_class
    @ttl = ttl
    @rdata = NetworkBuffer.serialize(:u8, rdata)
  end

  # TODO: Consolidate all label serialization and deserialization functions
  private def serialize_labels(buffer, values)
    values.each { |value| buffer.write_string!(value, :u8) }
    buffer.write8!(0)
  end

  private_class_method def self.deserialize_labels(buffer)
    labels = []

    loop do
      length = buffer.read_u8!

      break if length.zero?

      labels << buffer.read_string!(length)
    end

    labels
  end
end
