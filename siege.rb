require 'socket'
array = []
100.times do |i|
	array << TCPSocket.new('localhost', 3000)
end

array.each_with_index do |socket, index| 
	Process.fork do
		socket.write("hey#{index}")
		puts socket.read(4)
	end
end
Process.wait
