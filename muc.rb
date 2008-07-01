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

    def initialize(irc_room, ircd, jid, pass, confhost)
		@ircd = ircd
		@irc_room = irc_room

    	@@config = { :jid => jid, :conf => confhost, :pass => pass }

		@cl = Jabber::Client.new(Jabber::JID.new(@@config[:jid]))
		@cl.connect
		@cl.auth(@@config[:pass])

	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
        @m.on_message { |time,nick,text|
            handle_message(time, nick, text)
        }
        @m.on_private_message { |time,nick,text|
            handle_private_message(time, nick, text)
        }
        @m.on_subject { |time,nick,subject| 
            @topic = subject
            @ircd.topic(@irc_room, nick, subject)
        }
		@topic = 'no topic is yet set'
		
        @m.on_join { @ircd.on_join(self) }
		@m.join(irc_room + '@' + @@config[:conf] + '/' + @ircd.nick)
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

    def priv_message(text, who)
	jid = @m.roster[who].from
	f = Jabber::Message.new(jid, text)
	f.type = :chat
	cl.send(f)	
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

    def handle_private_message(time, nick, text)
        if time.nil? then
            text.gsub(%r{^/me (.*)$}) { "\001ACTION #{$1}\001" }.split("\n").each { |irctext|
                @ircd.priv_message(@irc_room, nick, irctext)
            }
        end
    end
end
