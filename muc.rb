require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'
require 'thread'

# how do we synchronise two asynchronous threads, both using callbacks?
# mutex?

class Muc
    attr_accessor :cl, :m, :topic

    def initialize(room)
#		@cl = Jabber::Client.new(Jabber::JID.new(config['jid']))
#		@cl.connect
#		@cl.auth(config['password'])
#	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
puts "spawning a muc in the muc"
		@topic = 'no topic is yet set'
		jmutex = Mutex.new()
		jmutex.lock()
		puts "spawning slow thread"
		Thread.new { sleep 10; jmutex.unlock() }
		puts "spinning on mutex at #{Time.now}"
		jmutex.lock()
		puts "unlocked mutex at #{Time.now}"
		jmutex.unlock()
		return self
    end

	def send(words)
		puts "->J: #{words}"
	end

end
