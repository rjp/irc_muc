require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'
require 'thread'

# how do we synchronise two asynchronous threads, both using callbacks?
# mutex?

class Muc
    attr_accessor :cl, :m, :topic, :ircd, :room

    def initialize(room, ircd)
		@ircd = ircd
		@room = room
		@gate = Hash.new { |h,k| h[k] = Mutex.new() }

#		@cl = Jabber::Client.new(Jabber::JID.new(config['jid']))
#		@cl.connect
#		@cl.auth(config['password'])
#	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
#		@m.on_join { jmutex.unlock() }
# @m.on_private_message { send_privmsgmessageircd.receive_line() } # hmm, no, ignore this, make real methods
# @m.on_message { ircd.receive_line() }
# @m.on_subject { |time,nick,subject| send_on_subject(subject) }
		puts "spawning a muc in the muc"
		@topic = 'no topic is yet set'
		
		jmutex = Mutex.new()
		jmutex.lock()
		puts "spawning slow thread"
		# @m.join(room << config['confserver'])
		Thread.new { sleep 5; jmutex.unlock() }
		puts "spinning on mutex at #{Time.now}"
		jmutex.lock()
		puts "unlocked mutex at #{Time.now}"
		jmutex.unlock()
		return self
    end

	def send(words)
		puts "->J: #{words}"
	end

	def send_on_subject(topic)
		@ircd.topic(@room, 'fish', 'gills')
	end
end
