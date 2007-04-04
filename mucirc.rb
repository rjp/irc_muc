#!/usr/bin/env ruby
$:.unshift '../../../../../lib/'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

$global_poo = nil
$global_j_users = ''
$global_subject = '(no topic set yet)'
$global_nick = nil

if ARGV.size != 5
  puts "Usage: #{$0} <jid> <password> <room@conference/nick> <port> <room>"
  exit
end

# Print a line formatted depending on time.nil?
def print_line(time, line)
  if time.nil?
    puts line
  else
    puts "#{time.strftime('%I:%M')} #{line}"
  end
end

#Jabber::debug = true
cl = Jabber::Client.new(Jabber::JID.new(ARGV[0]))
cl.connect
cl.auth(ARGV[1])

# This is the SimpleMUCClient helper!
m = Jabber::MUC::SimpleMUCClient.new(cl)
jnick = ARGV[2].gsub(%r{^.*/}, '')

require 'socket'
port = (ARGV[3] || 6692).to_i
server = TCPServer.new('localhost', port)

Thread.new {
    nick = jnick
	loop do
	  Thread.start(server.accept) do |s|
        $global_poo = s
        print(s, " is accepted (#{$global_poo})\n")
        begin
		    while s.gets do
                puts $_.chomp
		        command, *args = $_.split(' ')
                puts "c=#{command} a=#{args.inspect}"
                case command 
                    when 'USER': 
                        s.write("375 #{nick} :- MOTD\n"); s.write("376 #{nick} :- END OF MOTD\n");
                    when 'NICK': 
                        i_nick = args[0]
                    when 'MODE':
                        if args[0] == '#bots' then
                            s.write(":jirc 324 #{nick} #bots +\n")
                        end
                    when 'WHO':
                        s.write(":jirc 352 #{nick} #bots ~rjp localhost jirc rjp H :0 fish\n")
                        s.write(":jirc 352 #{nick} #bots ~badger localhost jirc badger H :0 fish\n")
                        s.write(":jirc 352 #{nick} #bots ~shoe localhost jirc shoe H :0 fish\n")
                        s.write(":jirc 315 #{nick} #bots :END OF WHO LIST\n")

#                   join #bots
#                   :badger!~badger@frottage.org JOIN :#bots
#                   :irc.pi.st 353 badger = #bots :badger @tbot
#                   :irc.pi.st 366 badger #bots :End of NAMES list
                    when 'JOIN':
                        chan = args[0]
                        puts("332 #{nick} #{chan} :fish\n")
                        s.write(":jirc 332 #{nick} #bots :#{$global_subject}\n")
                        puts("353 #{chan} :#{nick} rjp\n")
                        s.write(":jirc 353 #{nick} = #{chan} :#{nick} #{$global_j_users}\n")
                        puts("366 #{chan} :END OF NAMES\n")
                        s.write(":jirc 366 #{nick} #{chan} :END OF NAMES\n")
                    when 'PRIVMSG':
                        receiver = args.shift
                        text = args.join(' ').gsub(/^:/, '')
                        puts "send [#{text}] to channel #{receiver}"
                        m.say(text)
                    when 'TOPIC':
                        receiver = args.shift
                        text = args.join(' ').gsub(/^:/, '')
                        m.subject = text
                    else
                        puts $_.chomp
                end
		    end
		    print(s, " is gone\n")
		    s.close
        catch
            puts "bork"
        end
	  end
    end
}

# For waking up...
mainthread = Thread.current

# SimpleMUCClient callback-blocks

m.on_join { |time,nick|
  print_line time, "#{nick} has joined!"
  puts "Users: " + m.roster.keys.join(', ')
  $global_j_users = m.roster.keys.join(' ')
  unless time
    puts "report new person #{nick} in the room"
  end
}
m.on_leave { |time,nick|
  print_line time, "#{nick} has left!"
  $global_j_users = m.roster.keys.join(' ')
  unless time
    puts "report that someone #{nick} has left the room"
  end
}

m.on_message { |time,nick,text|
  print_line time, "<#{nick}> #{text}"

  if nick == jnick then
      puts "I should ignore [#{jnick}]"
      time = Time.now
  end

  # Avoid reacting on messaged delivered as room history
  unless time 
    puts (":#{nick}!~#{nick}@localhost PRIVMSG #bots :#{text}")
    $global_poo.write(":#{nick}!~#{nick}@frottage.org PRIVMSG #bots :#{text}\n")
    # Bot: invite astro@spaceboyz.net
    if text.strip =~ /^(.+?): invite (.+)$/
      jid = $2
      if $1.downcase == m.jid.resource.downcase
        m.invite(jid => "Inviting you on behalf of #{nick}")
        m.say("Inviting #{jid}...")
      end
    # Bot: subject This is room is powered by XMPP4R
    elsif text.strip =~ /^(.+?): subject (.+)$/
      if $1.downcase == m.jid.resource.downcase
        m.subject = $2
      end
    # Bot: exit please
    elsif text.strip =~ /^(.+?): exit please$/
      if $1.downcase == m.jid.resource.downcase
        puts "exiting"
        m.exit "Exiting on behalf of #{nick}"
        mainthread.wakeup
      end
    end
  end
}
m.on_room_message { |time,text|
  print_line time, "- #{text}"
}
m.on_subject { |time,nick,subject|
  print_line time, "*** (#{nick}) #{subject}"
  puts "set the topic to [#{subject}] by #{nick}"
  $global_subject = subject
  unless $global_poo.nil? then
        $global_poo.write(":jirc 332 #{jnick} #bots :#{$global_subject}\n")
  end
}

m.join(ARGV[2])

# Wait for being waken up by m.on_message
Thread.stop

cl.close

