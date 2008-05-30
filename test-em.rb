require 'rubygems'
require 'eventmachine'

require 'ircd'

EventMachine::run {
    EventMachine.epoll
    EventMachine::start_server('0.0.0.0', 6690, Ircd)
    puts "Listening..."
}
