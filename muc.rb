require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'

class Muc
    attr_accessor :cl, :m, :topic

    def initialize(room)
#		@cl = Jabber::Client.new(Jabber::JID.new(config['jid']))
#		@cl.connect
#		@cl.auth(config['password'])
#	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
puts "spawning a muc in the muc"
		@topic = 'no topic is yet set'
		return self
    end

	def send(words)
		puts "->J: #{words}"
	end

end
