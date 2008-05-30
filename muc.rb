require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'

class Muc
    attr_accessor :cl, :m

    def initialize(room, config)
		@cl = Jabber::Client.new(Jabber::JID.new(config['jid']))
		@cl.connect
		@cl.auth(config['password'])
	    @m = Jabber::MUC::SimpleMUCClient.new(@cl)
    end
end
