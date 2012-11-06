require 'socket'
socket1 = TCPSocket.new('localhost', 3000)
socket2 = TCPSocket.new('localhost', 3000)
socket1.write("hey")
socket2.write("hey")