require 'socket'
array = []
server = TCPServer.new(3000)
Process.fork do
	loop do
		server.accept
		puts 'accepted another connection!'
		array << server
	end
end
loop do
	puts array.size
end
Process.wait