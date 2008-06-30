require 'muc'
require 'config'


=begin

IRC server implemented as an EventMachine eventer

=end


class Ircd
    attr_accessor :muc, :nick, :socket, :user, :pass

    def send_data(data)
        @socket.write data
    end

    def crlf(args)
        self.send_data(*args << "\n")
		puts ">>[#{args.chomp}]"
    end

    def wb(code, nick, dest, words)
    	crlf(":jirc #{code} #{nick} #{dest} #{words}")
	end

    def post_init()
        puts "connected"
# :localhost NOTICE AUTH :BitlBee-IRCd initialized, please go on
        crlf(":jirc NOTICE AUTH :ircmuc initialised, continue")
    end

    def receive_line(line)
        command, *args = line.chomp.gsub(/\r/, '').split(' ')
        puts "c=[#{command}] a=[#{args.inspect}]"

        case command
        when 'NICK':
            @nick = args[0].gsub(/^:/,'')
		# rjp%jabber.pi.st@conference.jabber.pi.st
        when 'USER':
			(x, user, server, confhost) = args[3].match(%r{^:(.+?)%(.+?)@(.+)}).to_a
			c = Config.instance()
			c.jid = "#{user}@#{server}"
			if confhost[-1].chr == '.' then
				confhost = confhost << server
			end
			c.conf = confhost
			c.dump
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
    			else # TODO work out who is who on which channel where
					muc = nick_to_jid(receiver)
puts "afterwards #{muc.class}"
                    muc.priv_message(text, receiver)
       			unless muc.roster[receiver].show.nil? then
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
		    @muc[chan], junk = Muc.new(chan, self)
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

    def priv_message(room, nick, text)
        crlf(":#{nick}!~#{nick}@p.q PRIVMSG #{nick}##{room} :#{text}")
    end

    def initialize()
        @muc = Hash.new()
    end

    def destroy()
    end

	def nick_to_jid(nick)
		possibles = []
		@muc.each { |n,m|
			m.roster.each { |k,v|
				if k == nick then
					possibles.push [m, v.from]
				end
			}
		}
		if possibles.size == 1 then
			return possibles[0][0]
		else
			# how do we tiebreak?
			throw Mushy
		end

	end
end
