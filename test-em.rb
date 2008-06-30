require 'socket'
require 'ircd'

server = TCPServer.new('localhost', ARGV[0])

ircd = Ircd.new()
Thread.start(server.accept) do |s|
	ircd.socket = s
	# TODO move all this to ircd
  	while s.gets do
		p $_
		ircd.receive_line($_.chomp.gsub(/\r/,''))
	    puts "accepting lines"
	end
end

Thread.stop

