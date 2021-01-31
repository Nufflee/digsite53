# References:
#   - RFC1035: https://tools.ietf.org/html/rfc1035
#   - Wikipedia: https://en.wikipedia.org/wiki/Domain_Name_System

require "socket"
require_relative "./network_buffer"
require_relative "./dns_question"
require_relative "./dns_answer"

server = UDPSocket.new

addr = Addrinfo.tcp "127.0.0.1", 6969

server.bind(*addr.ip_unpack)

puts "Server listening on #{addr.ip_to_s}"

DNSRequest = Struct.new(:question, :client_addr)

DNS_OPCODES = %i[Query IQuery Status Notify Update].freeze

DNS_RECORD_TYPES = {
  1 => :A,
  28 => :AAAA
}.freeze

DNS_RECORD_CLASSES = {
  1 => :Internet
}.freeze

request_queue = Queue.new

producer_thread = Thread.new do
  loop do
    data, (_, client_port, client_ip) = server.recvfrom 65_535

    request = DNSQuestion.deserialize NetworkBuffer.new data
    header = request.header

    puts "-" * 10
    puts "Raw: #{data.inspect}"
    puts "Identification: #{header.id}, Header: #{'%08b' % header.control_field}, Opcode: #{header.opcode}, Question Count: #{header.question_count}"

    raise "Cannot handle requests with more than 1 question (got #{header.question_count})" unless header.question_count == 1
    raise "Query bit is not set in the header" unless header.control_field.get_bit(0).zero?
    raise "Truncated messages are currently not supported" unless header.control_field.get_bit(7).zero?
    raise "Error code set in query" unless header.control_field.slice_bits(12, 4).zero?
    raise "Unsupported opcode '#{header.opcode}', currently only support Query" unless header.opcode == :Query

    raise "Record type: #{request.record_type} not supported, currently only support #{DNS_RECORD_TYPES.values}" unless DNS_RECORD_TYPES.value?(request.record_type)
    raise "Record class: #{request.record_class} not supported, currently only support Internet" unless request.record_class == :Internet

    puts "Record Type: #{request.record_type}, Class: #{request.record_class}"
    puts "-" * 10

    request_queue << DNSRequest.new(request, Addrinfo.udp(client_ip, client_port))
  end
end

# Consumer
Thread.new do
  loop do
    request = request_queue.pop
    question = request.question
    header = question.header

    puts "Processing #{question}"

    ttl = 1

    case question.record_type
    when :A
      rdata = [69] * 4
    when :AAAA
      rdata = [0x69] * 16
    end

    answer = DNSAnswer.new(DNSHeader.new(header.id, 1 << 15, 0, 1, 0, 0), question.labels, DNS_RECORD_TYPES.invert[question.record_type], DNS_RECORD_CLASSES.invert[question.record_class], ttl,
                           rdata).serialize

    puts "Sending response: #{answer.buffer.inspect}"

    server.send answer.buffer, 0, *request.client_addr.ip_unpack
  end
end

producer_thread.join
