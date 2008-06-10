require 'socket'
require 'ircd'

config = {}
port = (config['port'] || 6690).to_i
server = TCPServer.new('localhost', port)

Thread.start(server.accept) do |s|
  	ircd = Ircd.new(s)
	puts "accepting lines"
	# TODO move all this to ircd
  	while s.gets do
		p $_
		ircd.receive_line($_.chomp.gsub(/\r/,''))
	end
end

Thread.stop

