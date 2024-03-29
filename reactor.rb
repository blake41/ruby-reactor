require 'socket'
require 'debugger'
require 'delegate'
require 'thread'

class Reactor

	def initialize
		@callbacks = []
		@mutex = Mutex.new
		@descriptors = {:read => [], :write => []}
	end

	def run
		loop do
			read_list = @descriptors[:read].collect {|io| io[:io]}
			write_list = [].tap do |list|
				@mutex.synchronize do	
					@descriptors[:write].each do |io|
						list << io[:io] if io[:io].data
					end
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
			Thread.pass
		end
	end

	def add_item(io, type, call_now = false, &block)
		if call_now == true
			callback = nil
			io = block.call(io)
		else
			callback = block
		end
		if type == :both
			my_io = MyIO.new(io)
			@mutex.synchronize do
				@descriptors[:read] << {:io => my_io, :callback => callback}
				@descriptors[:write] << {:io => my_io, :callback => callback}
			end
		else
			@mutex.synchronize do
				@descriptors[type] << {:io => MyIO.new(io), :callback => callback}
			end
		end
	end

	def add_server(port)
		Thread.new do
			server = TCPServer.new(port)
			loop do
				puts 'waiting for connection'
				connection = server.accept
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
		begin
			@data = @io.read_nonblock(@length)
		rescue EOFError
		end
	end

	def do_write
		bytes = @io.write_nonblock(@data)
		@data.slice!(0, bytes)
	end

end

reactor = Reactor.new
reactor.add_server(3000)
reactor.run