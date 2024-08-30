$stdout.sync = true

require_relative 'twitchchat/client'
require_relative 'twitchchat/runner'
require_relative 'twitchchat/trivia'

module Twitchchat

end

TwitchChat::Runner.new.run
