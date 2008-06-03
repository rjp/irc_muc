require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'
require 'thread'

# Jabber::debug = true

# how do we synchronise two asynchronous threads, both using callbacks?
# mutex?

class Muc
    attr_accessor :cl, :m, :topic, :ircd, :irc_room

    @@config = YAML.load_file('quick.yaml')
    p @@config

    def initialize(irc_room, ircd)
		@ircd = ircd
		@irc_room = irc_room
		@gate = Hash.new { |h,k| h[k] = Mutex.new() }

		@cl = Jabber::Client.new(Jabber::JID.new(@@config[:jid]))
		@cl.connect
		@cl.auth(@@config[:pass])
	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
#		@m.on_join { jmutex.unlock() }
# @m.on_private_message { ircd.receive_line() } # hmm, no, ignore this, make real methods
        @m.on_message { |time,nick,text|
            handle_message(time, nick, text)
        }
        @m.on_subject { |time,nick,subject| 
            @topic = subject
            @ircd.topic(@irc_room, nick, subject)
        }
		@topic = 'no topic is yet set'
		
		jmutex = Mutex.new()
		jmutex.lock()
    @m.on_join { jmutex.unlock() }
		@m.join(irc_room + '@' + @@config[:conf] + '/' + @ircd.nick)
		jmutex.lock()
		jmutex.unlock()
		return self, irc_room
    end

	def send(words)
		puts "->J: #{words}"
	end

    def roster
        @m.roster
    end

	def set_subject(topic)
		m.subject = topic
	end

    def chan_message(text)
        @m.say(text)
    end 

    def handle_message(time, nick, text)
        if nick != @ircd.nick then
            if time.nil? then
            text.gsub(%r{^/me (.*)$}) { "\001ACTION #{$1}\001" }.split("\n").each { |irctext|
                @ircd.chan_message(@irc_room, nick, irctext)
            }
        end
        end
    end
end
