require 'rubygems'
require 'eventmachine'

=begin

IRC server implemented as an EventMachine eventer

=end


class Ircd < EventMachine::Connection
    attr_accessor :muc, :nick

    include EventMachine::Protocols::LineText2

    def crlf(args)
        self.send_data(*args << "\r\n")
    end

    def post_init()
        puts "connected"
# :localhost NOTICE AUTH :BitlBee-IRCd initialized, please go on
        crlf(":localhost NOTICE AUTH :ircmuc initialised, continue")
        @muc = Hash.new()
    end

    def receive_line(line)
        command, *args = line.chomp.gsub(/\r/, '').split(' ')
        puts "c=[#{command}] a=[#{args.inspect}]"
        case command
        when 'NICK':
            @nick = args[0]
        when 'USER':
            crlf("375 #{@nick} :- MOTD")
            crlf("376 #{@nick} :- END OF MOTD")
        when 'JOIN':
            c_join(args[0].gsub(/^#/,''))
        end
    end

	# spawn a muc connecting us to a particular room
    def c_join(chan)
        puts "spawning a muc for #{chan}@server/#{@nick}"
		# cb = proc { @muc[chan] = Muc.new(chan) }
		# how do we return stuff from a defered event?
		# defer(cb, proc { self.on_join(chan) })
    end

	def on_join(chan)
		@muc[chan] = something
	end

	# quit the IRC session, gracefully closing all the mucs first
	def c_quit()
    	puts "closing mucs"
	# @muc.each {|chan,mucobj| }
	# callback
	end
end
