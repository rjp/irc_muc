class Config
	include Singleton

	attr_accessor :jid, :pass, :conf

	def initialize()
	end

	def dump
		puts "#{self.id} dump: #{@jid} #{@pass} #{@conf}"
	end
end
