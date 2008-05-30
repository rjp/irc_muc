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
            c_join(args[0])
        end
    end

    def c_join(chan)
        puts "spawning a muc for #{chan.gsub(/^#/,'')}@server/#{@nick}"
# cb = proc { @muc[chan] = Muc.new(chan.gsub(/^#/,'')) }
# defer(cb, self.on_join)
    end
end
