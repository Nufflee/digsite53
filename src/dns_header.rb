require_relative "./serializable"
require_relative "./extensions"

class DNSHeader < Serializable
  # Header
  attr_serialize_reader :u16, :id
  attr_serialize_reader :u16, :control_field
  attr_serialize_reader :u16, :question_count
  attr_serialize_reader :u16, :answer_count
  attr_serialize_reader :u16, :nameserver_count
  attr_serialize_reader :u16, :additional_count

  generate_constructor

  def opcode
    DNS_OPCODES[@control_field.slice_bits(1, 4)]
  end
end
