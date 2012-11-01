require 'socket'
require 'debugger'
require 'delegate'
require 'thread'

class Reactor

	def initialize
		@callbacks = []
		@queue = Queue.new
		@descriptors = []
	end

	def run
		loop do
			while @queue.size > 0
				@descriptors << @queue.pop
			end
			read_list = @descriptors[:read].collect {|io| io[:io]}
			write_list = [].tap do |list|
				@descriptors[:write].each do |io|
					list << io[:io] if io[:io].data
				end
			end
			readers, writers = IO.select(read_list, write_list, nil, 1)
			if !readers.nil?
				if !readers.empty?
					readers.each do |reader|
						reader.do_read
					end
				end
			end
			if !writers.nil?
				if !writers.empty?
					writers.each do |writer|
						writer.do_write
					end
				end
			end
			[:read, :write].each do |mode|
				@descriptors[mode].each do |io_pair|
					@callbacks << io_pair if io_pair[:callback]
				end
				@callbacks.each do |io|
					callback.call(io[:io])
				end
			end
		end
	end

	def add_item(io, type, call_now = false, &block)
		descriptors = {:read => [], :write => []}
		if call_now == true
			callback = nil
			io = block.call(io)
		else
			callback = block
		end
		if type == :both
			my_io = MyIO.new(io)
			descriptors[:read] << {:io => my_io, :callback => callback}
			descriptors[:write] << {:io => my_io, :callback => callback}
		else
			descriptors[type] << {:io => MyIO.new(io), :callback => callback}
		end
		@queue << descriptors
	end

	def add_server(port)
		Thread.new do
			loop do
				server = TCPServer.new(port)
				puts 'waiting for connection'
				connection = server.accept
				puts 'accepted connection'
				self.add_item(connection, :both)
			end
		end
	end
end

class MyIO < DelegateClass(IO)

	attr_accessor :data, :io

	def initialize(io)
		@io = io
		@length = 1024 * 16
		super(io)
	end

	def do_read
		@data = @io.read_nonblock(@length)
		puts @data
	end

	def do_write
		bytes = @io.write_nonblock(@data)
		@data.slice!(0, bytes)
	end

end

reactor = Reactor.new
reactor.add_server(3000)
reactor.run