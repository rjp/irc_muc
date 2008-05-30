require 'rubygems'
require 'eventmachine'

=begin

IRC server implemented as an EventMachine eventer

=end

class Ircd < EventMachine::Connection
    include EventMachine::Protocols::LineText2

    def crlf(args)
        self.send_data(*args << "\r\n")
    end


    def post_init()
        puts "connected"
# :localhost NOTICE AUTH :BitlBee-IRCd initialized, please go on
        crlf(":localhost NOTICE AUTH :ircmuc initialised, continue")
    end

    def receive_line(line)
        command, *args = line.chomp.gsub(/\r/, '').split(' ')
        puts "c=[#{command}] a=[#{args.inspect}]"
    end
end
