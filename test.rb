require 'thread'

# @queue = Queue.new

# @queue << Object.new
# @queue.pop
# t = Thread.new do
# 	loop do
# 		@queue.pop
# 		puts "#{Thread.current}"
# 	end
# end
# t.join
# Thread.new do
# 	loop do
# 		puts "im in spawned thread"
# 		queue << Object.new
# 		fake = queue.pop
# 		puts fake
# 		queue << fake
# 	end
# end

# loop do
# 	puts 'im in main thread'
# 	queue.pop
# end

puts "main loop is #{Thread.current}"
sleep 3
loop do
	puts Thread.current
end

Thread.new do
	loop do
		puts Thread.current
	end
end