$stdout.sync = true
require File.expand_path('../../../config/environment', __FILE__)

class TwitchChat
  class Runner
    def run
      client = Client.new({ user: Rails.application.credentials.twitch[:user], token: Rails.application.credentials.twitch[:token] })
      client.listen

      while (client.running) do
      end
    end
  end
end
