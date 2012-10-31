require 'socket'
require 'debugger'
require 'delegate'

class Reactor

	def initialize
		@descriptors = { :read => [], :write => []}
		@callbacks = []
	end

	def run
		loop do
			read_list = @descriptors[:read].collect {|io| io[:io]}
			write_list = [].tap do |list|
				@descriptors[:write].each do |io|
					list << io[:io] if io[:io].data
				end
			end
			readers, writers = IO.select(read_list, write_list, nil)
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
		if call_now == true
			callback = nil
			io = block.call(io)
		else
			callback = block
		end
		if type == :both
			my_io = MyIO.new(io)
			@descriptors[:read] << {:io => my_io, :callback => callback}
			@descriptors[:write] << {:io => my_io, :callback => callback}
		else
			@descriptors[type] << {:io => MyIO.new(io), :callback => callback}
		end
	end

	def add_server(port)
		# server = TCPServer.new(port)
		# self.add_item(server, :both, true) do |server|
		# 	puts 'waiting for connection'
		# 	connection = server.accept
		# end
		parent_pid = Process.pid
		@child_pids = []
		pid = Process.fork do
			# server = [].tap do |arrray|
			# 	@descriptors[:read].each do |item|
			# 		debugger
			# 		item[:io].io.is_a?(TCPSocket)
			# 		array << item[:io]
			# 	end
			# end
			self.trap_signals([parent_pid])
			loop do
				server = TCPServer.new(port)
				puts 'waiting for connection'
				connection = server.accept
				self.add_item(connection, :both)
				# NEED TO USE A SOCKET OR PIPE HERE SO I CAN COMMUNICATE ACROSS PROCESSES
				# I think it will only work using threads and a queue because you can toss objects on a queue
			end
		end
		@child_pids << pid
		self.trap_signals(@child_pids)
	end

	def trap_signals(pids)
		[:INT, :QUIT].each do |signal|
			Signal.trap(signal) do
				pids.each do |pid|
					Process.kill(signal, pid)
				end
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
	end

	def do_write
		bytes = @io.write_nonblock(@data)
		@data.slice!(0, bytes)
	end

end

reactor = Reactor.new
reactor.add_server(3000)
reactor.run