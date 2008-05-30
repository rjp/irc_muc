require 'rubygems'
require 'eventmachine'
require 'protocols/linetext2'
require 'ircd'

EventMachine::run {
    EventMachine.epoll
    EventMachine::start_server('0.0.0.0', 6990, Ircd)
    puts "Listening..."
}
