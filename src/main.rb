# References:
#   - RFC1035: https://tools.ietf.org/html/rfc1035
#   - Wikipedia: https://en.wikipedia.org/wiki/Domain_Name_System

require "socket"
require_relative "./extensions.rb"
require_relative "./network_buffer.rb"

server = UDPSocket.new

addr = Addrinfo.tcp "127.0.0.1", 6969

server.bind *addr.ip_unpack

puts "Server listening on #{addr.ip_to_s}"

DNSQuestion = Struct.new(:labels, :record_type, :record_class)
DNSRequest = Struct.new(:id, :opcode, :questions, :client_addr)

dns_opcodes = [:Query, :IQuery, :Status, :Notify, :Update]

dns_record_types = {
  1 => :A,
  28 => :AAAA,
}

dns_record_classes = {
  1 => :Internet,
}

request_queue = Queue.new

producer_thread = Thread.new do
  loop {
    data, (_, client_port, client_ip) = server.recvfrom 65535

    buffer = NetworkBuffer.new data

    id_field, control_field, question_count, answer_count, nameserver_count, additional_count = buffer.read_u16!(6)

    opcode = dns_opcodes[control_field.slice_bits(1, 4)]

    puts "-" * 10
    puts "Raw: #{data.inspect}"
    puts "Identification: #{id_field.to_s}, Header: #{"%08b" % control_field}, Opcode: #{opcode}, Question Count: #{question_count}"

    raise "Cannot handle requests with more than 1 question (got #{question_count})" unless question_count == 1
    raise "Query bit is not set in the header" unless control_field.get_bit(0) == 0
    raise "Truncated messages are currently not supported" unless control_field.get_bit(7) == 0
    raise "Error code set in query" unless control_field.slice_bits(12, 4) == 0
    raise "Unsupported opcode '#{opcode}', currently only support Query" unless opcode == :Query

    labels = []

    loop {
      length = buffer.read_u8!

      if length == 0
        break
      end

      labels << buffer.read_string!(length)
    }

    puts "Labels: #{labels}"

    record_type = dns_record_types[buffer.read_u16!]
    record_class = dns_record_classes[buffer.read_u16!]

    raise "Record type: #{record_type} not supported, currently only support #{dns_record_types.values}" unless dns_record_types.has_value?(record_type)
    raise "Record class: #{record_class} not supported, currently only support Internet" unless record_class == :Internet

    puts "Record Type: #{record_type}, Class: #{record_class}"
    puts "-" * 10

    request = DNSRequest.new(id_field, opcode, [DNSQuestion.new(labels, record_type, record_class)], Addrinfo.udp(client_ip, client_port))

    request_queue << request
  }
end

# Consumer
consumer_thread = Thread.new do
  loop {
    request = request_queue.pop
    question = request.questions[0]

    message = NetworkBuffer.new

    puts "Processing #{request}"

    ## Header
    # Identification
    message.write16!(request.id)

    # Control Field
    control_field = 0
    control_field |= 1 << 15 # Response bit
    message.write16!(control_field)

    # Counts (1 for answer RR count)
    message.write16!([0, 1, 0, 0])

    ## RR
    # Domain labels
    question.labels.each do |label|
      message.write8!(label.length)
      message.write_string!(label)
    end

    # Domain label null terminator
    message.write8!(0)

    # RR Type
    message.write16!(dns_record_types.invert[question.record_type])

    # RR Class
    message.write16!(dns_record_classes.invert[question.record_class])

    # TTL
    message.write32!(1)

    # RDATA and its length
    if question.record_type == :A
      message.write16!(4)
      message.write8!([69] * 4)
    elsif question.record_type == :AAAA
      message.write16!(16)
      message.write16!([0x6969] * 8)
    end

    puts "Sending response: #{message.buffer.inspect}"

    server.send message.buffer, 0, *request.client_addr.ip_unpack
  }
end

producer_thread.join
