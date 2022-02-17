$stdout.sync = true

require_relative 'twitchchat/client'
require_relative 'twitchchat/runner'

module Twitchchat

end

TwitchChat::Runner.new.run