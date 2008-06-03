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
# @m.on_message { ircd.receive_line() }
# @m.on_subject { |time,nick,subject| @subjectircd.topic(@irc_room, nick, subject); @gate[:subject].unlock() }
		puts "spawning a muc in the muc"
		@topic = 'no topic is yet set'
		
		jmutex = Mutex.new()
		jmutex.lock()
    @m.on_join { jmutex.unlock() }
		puts "spawning slow thread for #{@ircd.nick} in #{irc_room}"
		@m.join(irc_room + '@' + @@config[:conf] + '/' + @ircd.nick)
		puts "spinning on mutex at #{Time.now} for #{@ircd.nick}"
		jmutex.lock()
		puts "unlocked mutex at #{Time.now}, my irc_room is #{irc_room}"
		jmutex.unlock()
		return self, irc_room
    end

	def send(words)
		puts "->J: #{words}"
	end

	def on_topic()
		@ircd.topic(@irc_room, 'fish', 'gills')
	end

	def set_subject(topic)
		@gate[:subject].lock()
		m.subject = topic
		@gate[:subject].lock() # spin here until we receive the on_subject callback
	end

    def chan_message(text)
        @m.say(text)
    end 
end
