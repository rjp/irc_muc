require 'socket'
require 'ircd'

if ARGV[0].nil? then
    puts <<ERROR
> ruby irc_muc.rb ircport

ircport is the port your IRC client will connect to.
ERROR
    exit(1)
end

server = TCPServer.new('localhost', ARGV[0])

ircd = Ircd.new()
Thread.start(server.accept) do |s|
	ircd.socket = s
	# TODO move all this to ircd
  	while s.gets do
		p $_
		ircd.receive_line($_.chomp.gsub(/\r/,''))
	end
end

Thread.stop

