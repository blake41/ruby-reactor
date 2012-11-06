require File.expand_path(File.join(File.dirname(__FILE__), 'blake_io'))
require 'socket'
require 'debugger'
array = []
server = TCPServer.new('localhost', 3000)
array << server.accept.fileno
array << server.accept.fileno
sleep 5
array.each do |connection|
	puts "file descriptor passed in:#{connection}"
end
highest = array.sort.last
file_descriptors_to_read = BlakeIO.select(array, highest)
file_descriptors_to_read.each do |file_descriptor|
	io = IO.new(file_descriptor)
	puts io.read_nonblock(3)
end