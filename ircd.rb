require 'muc'


=begin

IRC server implemented as an EventMachine eventer

=end


class Ircd
    attr_accessor :muc, :nick

    def crlf(args)
        self.send_data(*args << "\n")
		puts ">>[#{args}]"
    end

    def wb(code, nick, dest, words)
    	crlf(":jirc #{code} #{nick} #{dest} #{words}")
		self.send_data('')
	end

    def post_init()
        puts "connected"
# :localhost NOTICE AUTH :BitlBee-IRCd initialized, please go on
        crlf(":jirc NOTICE AUTH :ircmuc initialised, continue")
        @muc = Hash.new()
    end

    def receive_line(line)
        command, *args = line.chomp.gsub(/\r/, '').split(' ')
        puts "c=[#{command}] a=[#{args.inspect}]"

        case command
        when 'NICK':
            @nick = args[0].gsub(/^:/,'')
        when 'USER':
            crlf("375 #{@nick} :- MOTD")
            crlf("376 #{@nick} :- END OF MOTD")
			crlf("001 #{@nick} :Welcome to muc")
        when 'JOIN':
            c_join(args[0].gsub(/^#/,''))
		when 'TOPIC':
			c_topic(args[0].gsub(/^#/,''), args[1].gsub(/^:/,''))
	when 'QUIT':
		c_quit()
        when 'PRIVMSG':
			receiver = args.shift
			text = args.join(' ').gsub(/^:/, '').gsub(%r{^\001ACTION },'/me ').gsub(%r{\001$}, '')
			case receiver
			    when /^#/: 
                    chan = receiver.gsub(/^#/,'')
                    @muc[chan].chan_message(text)
			    when /^&/: $log.info("ignoring message to #{receiver}")
    			else @muc.say(text, receiver)
       			unless @muc.roster[receiver].show.nil? then
     			    s.write(":jirc 301 #{nick} #{receiver} :#{m.roster[receiver].status}\n")
    			end
			end
        end
    end

	def c_topic(chan, topic)
		@muc[chan].set_subject(topic) # has to be a method
    end

	# spawn a muc connecting us to a particular room
    def c_join(chan)
        if @muc[chan].nil? then
		Muc.new(chan, self)
#cb = proc { return Muc.new(chan, self) }
#	    	oj = proc {|muc| @muc[chan] = muc; self.on_join(muc) }
#		    EventMachine::defer(cb, oj)
        else
            on_join(muc)
        end
    end

	def on_join(muc)
        chan = muc.irc_room
		crlf(":#{@nick} JOIN ##{chan}")
		wb(332, @nick, "##{chan}", ":#{muc.topic}")
		wb(353, @nick, "= ##{chan}", ":#{nick} " + muc.roster.keys.join(' '))
		wb(366, @nick, "##{chan}", ":END OF NAMES")
	end

	# quit the IRC session, gracefully closing all the mucs first
	def c_quit()
    	puts "closing mucs"
	cb = proc { 
		sleep 5
		return 1
	}
#	@muc.each {|chan,mucobj| }
#	EventMachine::defer (cb, proc {|r| on_quit(r)})
	end

	def on_quit(r)
		crlf('BYE')
		self.close_connection()
	end

	def topic(room, nick, topic)
		wb(332, nick, "##{room}", ":#{topic}")
	end

    def chan_message(room, nick, text)
        crlf(":#{nick}!~#{nick}@p.q PRIVMSG ##{room} :#{text}")
    end

    def initialize()
    end

    def destroy()
    end
end
