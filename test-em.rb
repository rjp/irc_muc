require 'socket'
require 'ircd'

config = {}
port = (config['port'] || 6990).to_i
server = TCPServer.new('localhost', port)

Thread.start(server.accept) do |s|
  	ircd = Ircd.new(s)
	# TODO move all this to ircd
  	while s.gets do
		p $_
		ircd.receive_line($_.chomp.gsub(/\r/,''))
	    puts "accepting lines"
	end
end

Thread.stop

