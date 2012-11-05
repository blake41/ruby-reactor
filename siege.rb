require 'socket'
array = []
1023.times do
	array << TCPSocket.new('localhost', 3000)
end

array.each_with_index do |socket, index|
	Process.fork do
		count = index.to_s.size
		to_read = count + 3
		socket.write("hey#{index}")
		puts socket.read(to_read)
	end
end
Process.wait
