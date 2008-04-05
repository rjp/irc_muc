#!/usr/bin/env ruby
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'xmpp4r/presence'
require 'yaml'

require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::INFO

options = {}

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: mucirc.rb [options]"

  opts.on("-d", "--[no-]debugging", "Output debugging") do |d|
    options[:debugging] = true
    $log.level = Logger::DEBUG
  end
  opts.on("-f", "--config FILE", "Config file") do |f|
    options[:configfile] = f
  end
end.parse!

$global_poo = nil
$global_j_users = ''
$global_subject = '(no topic set yet)'
$global_nick = nil
$global_chan = nil
$global_away = {}

config = {}
begin
    global_config = YAML.load_file(options[:configfile])
    default = global_config['default'] || (global_config.keys.sort)[0]
    config = global_config[ARGV[0]] || global_config[default]
rescue => e
    puts "Usage: #{$0} config.yml [#{e}]"
    exit
end

# config = { 'jid' => ARGV[0], 'password' => ARGV[1], 'room' => ARGV[2], 'port' => ARGV[3], 'irc' => ARGV[4] }

# Print a line formatted depending on time.nil?
def print_line(time, line)
  if time.nil?
    $log.debug("+ #{line}")
  else
    $log.debug("#{time.strftime('%I:%M')} #{line}")
  end
end

#Jabber::debug = true
cl = Jabber::Client.new(Jabber::JID.new(config['jid']))
cl.connect
cl.auth(config['password'])

# This is the SimpleMUCClient helper!
m = Jabber::MUC::SimpleMUCClient.new(cl)
jnick = config['room'].gsub(%r{^.*/}, '')

require 'socket'
port = (config['port'] || 6692).to_i
server = TCPServer.new('localhost', port)

Thread.new {
    nick = jnick
	loop do
      $log.info("Waiting for IRC connection on port #{config['port']}")
	  Thread.start(server.accept) do |s|
        $global_poo = s
        $log.debug("#{s} is accepted (#{$global_poo})\n")
        begin
		    while s.gets do
		        command, *args = $_.chomp.gsub(/\r/, '').split(' ')
                $log.debug("c=#{command} a=#{args.inspect}")
                case command 
                    when 'WHOWAS':
                        onick = args[0].to_s
                        s.write(":jirc 369 #{nick} #{onick} :End of WHOWAS list\n")
                    when 'WHOIS': 
                        onick = args[0].to_s
                        if m.roster[args[0]].nil? then
                            s.write(":jirc 401 #{nick} #{onick} :No such nick or channel name\n")
                            $log.debug(":jirc 401 #{nick} #{onick} :No such nick or channel name")
                        else
                            $log.debug("id=#{m.roster[onick].id} from=#{m.roster[onick].from}")
                            $log.debug("#{m.roster[onick].x.first_element('item').methods.sort.join(' ')}")
                            m.roster[onick].x.each_element { |p| $log.debug(p.inspect) }
                            realname = m.roster[onick].x.first_element('item').jid
                            s.write(":jirc 311 #{nick} #{onick} ~#{onick}. localhost * :#{realname}\n")
                            s.write(":jirc 319 #{nick} #{onick} :+#{$global_chan}\n")
                            s.write(":jirc 318 #{nick} #{onick} :End of WHOIS\n")
                        end
                    when 'AWAY':
                        away = args[0]
                        pres = Jabber::Presence.new
                        pres.to = config['room'].gsub(%r{/.*$}, '')
                        pres.from = config['jid']
                        pres.type = :available
                        if away == ':' then
                            pres.show = nil
                            pres.status = nil
                            s.write(":jirc 305 #{nick} :You are no longer away\n")
                        else
                            pres.show = :away
                            pres.status = away.gsub(/^:/, '')
                            s.write(":jirc 306 #{nick} :You are away\n")
                        end
                        m.send(pres)
                    when 'USER': 
                        s.write("375 #{nick} :- MOTD\n"); s.write("376 #{nick} :- END OF MOTD\n");
			s.write("001 Welcome to Jabber Gateway #{nick}\n")
                    when 'NICK': 
                        i_nick = args[0]
                    when 'MODE':
                        if args[0] == $global_chan then
                            s.write(":jirc 324 #{nick} #{$global_chan} +\n")
                        end
                    when 'WHO':
                        m.roster.keys.each { |who|
                            s.write(":jirc 352 #{who} #{$global_chan} ~who localhost jirc who H :0\n")
                        }
                        s.write(":jirc 315 #{nick} #{$global_chan} :END OF WHO LIST\n")

#                   join #bots
#                   :badger!~badger@frottage.org JOIN :#bots
#                   :irc.pi.st 353 badger = #bots :badger @tbot
#                   :irc.pi.st 366 badger #bots :End of NAMES list
                    when 'JOIN':
                        chan = args[0]
# when you join a channel, that's the only one you're in.  kinda.
                        $global_chan = chan 
                        jchan = chan.gsub(/^#/,'') << '@conference.jabber.pi.st/' << nick
                        $log.debug("in future, I will join jabber://#{jchan}")
                        s.write(":jirc 332 #{nick} #{chan} :#{$global_subject}\n")
                        s.write(":jirc 353 #{nick} = #{chan} :#{nick} #{$global_j_users}\n")
                        s.write(":jirc 366 #{nick} #{chan} :END OF NAMES\n")
                    when 'PRIVMSG':
                        receiver = args.shift
                        text = args.join(' ').gsub(/^:/, '').gsub(%r{^\001ACTION },'/me ').gsub(%r{\001$}, '')
                        $log.debug("send [#{text}] to channel #{receiver}")
                        case receiver
                            when /^#/: m.say(text)
                            when /^&/: $log.info("ignoring message to #{receiver}")
                            else m.say(text, receiver)
                                unless m.roster[receiver].show.nil? then
                                    s.write(":jirc 301 #{nick} #{receiver} :#{m.roster[receiver].status}\n")
                                end
                        end
                    when 'TOPIC':
                        receiver = args.shift
                        text = args.join(' ').gsub(/^:/, '')
                        m.subject = text
                        s.write(":#{nick} TOPIC #{receiver} :#{text}\n")
                    else
                        $log.warn("Unhandled IRC: #{$_.chomp}")
                end
		    end
            $global_poo = nil
		    $log.debug("#{s} is gone\n")
		    s.close
        rescue => bork
            $global_poo = nil
            $log.error("#{bork}, restarting accept")
        end
	  end
    end
}

# For waking up...
mainthread = Thread.current

# SimpleMUCClient callback-blocks
m.add_presence_callback { |x|
    $log.debug("#{x.type||'NIL'} #{x.show} #{x.status} #{x.from} #{x.to}")
    unless $global_poo.nil? then
        nick = x.from.to_s.gsub(%r{^.*/}, '')

	    if x.show.nil? then # available
	        $log.debug("UNAWAY from #{x.from} -> #{nick}")
            $global_poo.write(":jirc 305 #{nick} :You are no longer away\n")
            $global_away[nick] = nil
	    else
	        $log.debug("AWAY from #{x.from} -> #{nick}")
            $global_poo.write(":jirc 306 #{nick} :You are away\n")
            $global_away[nick] = x.status
	    end
    end
}

m.on_join { |time,nick|
  print_line time, "#{nick} has joined!"
  $global_j_users = m.roster.keys.join(' ')
    unless time
    $log.debug("#{nick}!~#{nick}@localhost JOIN :#{$global_chan}")
        unless $global_poo.nil? 
            $global_poo.write(":#{nick}!~#{nick}@localhost JOIN :#{$global_chan}\n")
        end
    end
}
m.on_leave { |time,nick|
  print_line time, "#{nick} has left!"
  $global_j_users = m.roster.keys.join(' ')
    unless time
        unless $global_poo.nil? 
            $log.debug("#{nick}!~#{nick}@localhost PART #{$global_chan} :#{nick}")
            $global_poo.write(":#{nick}!~#{nick}@localhost PART #{$global_chan} :#{nick}\n")
        end
    end
}

m.on_private_message { |time,nick,text|
  if nick == jnick then
      time = Time.now # FUDGE
  end
  # Avoid reacting on messaged delivered as room history
  unless time 
    unless $global_poo.nil?
	    irctext = text.gsub(%r{^/me (.*)$}) { "\001ACTION #{$1}\001" }
	    $global_poo.write(":#{nick}!~#{nick}@frottage.org PRIVMSG #{jnick} :#{irctext}\n")
    end
  end
}

m.on_message { |time,nick,text|
  print_line time, "<#{nick}> #{text}"

  if nick == jnick then
      time = Time.now # FUDGE
  end

  # Avoid reacting on messaged delivered as room history
  unless time 
    unless $global_poo.nil?
        text.gsub(%r{^/me (.*)$}) { "\001ACTION #{$1}\001" }.split("\n").each { |irctext|
	        $log.debug(":#{nick}!~#{nick}@localhost PRIVMSG #{$global_chan} :#{irctext} [[#{text}]]")
	        $global_poo.write(":#{nick}!~#{nick}@frottage.org PRIVMSG #{$global_chan} :#{irctext}\n")
        }
    end
  end
}
m.on_room_message { |time,text|
  print_line time, "- #{text}"
}
m.on_subject { |time,nick,subject|
  print_line time, "*** (#{nick}) #{subject}"
  $global_subject = subject
  unless time
	  unless $global_poo.nil? then
            $log.info("set the topic to [#{subject}] by #{nick}")
	        $global_poo.write(":jirc 332 #{nick} #{$global_chan} :#{$global_subject}\n")
	  end
  end
}

m.join(config['room'])

# Wait for being waken up by m.on_message
Thread.stop

cl.close

