require 'socket'
require 'logger'

$stdout.sync = true

Thread.abort_on_exception = true

class TwitchChat
  class Client
    attr_reader :logger, :running, :socket

    def initialize(auth, logger: nil)
      @auth    = auth
      @logger  = logger || Logger.new(STDOUT)
      @running = false
      @socket  = nil
    end

    def send(message)
      logger.info "< #{message}"
      socket.puts(message)
    end

    def listen
      connect

      Thread.start do
        while (running) do
          ready = IO.select([socket])

          ready[0].each do |s|
            line    = s.gets.strip
            logger.info "> #{line}"
            interpret_line(line)
          end
        end
      end
    end

    def connect
      open_socket
      logger.info 'Preparing to connect...'
      socket.puts("PASS #{@auth[:token]}")
      socket.puts("NICK #{@auth[:user]}")

      logger.info 'Connected...'
      send('CAP REQ :twitch.tv/tags')
      send('CAP REQ :twitch.tv/commands')
      send('JOIN #sophiediy')
      send('PRIVMSG #sophiediy :Séquence d\'initialisation complète.')
    end

    def stop
      @running = false
    end

    private

    def open_socket
      @socket = TCPSocket.new('irc.chat.twitch.tv', 6667)
      @socket.set_encoding 'UTF-8'
      @running = true
    end

    def interpret_line(line)
      case line
      when 'PING :tmi.twitch.tv'
        send('PONG :tmi.twitch.tv')
      end

      match   = line.match(/^.+display-name=(\w+);.+ PRIVMSG #(\w+) :(.+)$/)

      if match
        user    = match[1]
        channel = match[2]
        message = match[3]

        #message = Message.create(channel: channel, user: user, message: message, raw: line)
      end
    end
  end
end

