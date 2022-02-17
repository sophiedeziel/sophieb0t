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

      #Thread.start do
        while (running) do
          ready = IO.select([socket])

          ready[0].each do |s|
            line    = s.gets.strip
            logger.info "> #{line}"
            interpret_line(line)
          end
        end
      #end
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
      #send('PRIVMSG #sophiediy :Séquence d\'initialisation complète.')
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

      match   = /^.+display-name=(?<user>\w+);.+ PRIVMSG #(?<channel>\w+) :(?<content>.+)$/.match(line)

      if match
        user    = match[:user]
        channel = match[:channel]
        content = match[:content]

        message = Message.create(channel: channel, user: user, message: content, raw: line)

        process_content(content)

      end
    end

    def process_content(content)
      case
      when content.start_with?('!cheers') && raw.match(/subscriber=1;/)
  
      when content.start_with?('!led ')
        match = content.match /!led (?<couleur>.+)/
        puts match[:couleur]
        led(match[:couleur])
      end
    end
  
    def led(color)
      states = {
        "bleu" => {state: "ON", color: { r: 0, g: 0, b: 255}},
        "rouge" => {state: "ON", color: { r: 255, g: 0, b: 0}},
        "vert" => {state: "ON", color: { r: 0, g: 255, b: 0}},
        "rose" => {state: "ON", color: { r: 255, g: 64, b: 64}},
        "rainbow" => {state: "ON", effect: "Rainbow"}
      }
      if states[color].present?
        send_mqtt(states[color])
      else
        send("PRIVMSG #sophiediy :#{color} n'existe pas.")
      end
    end

    def send_mqtt(settings)
      Thread.current[:mqtt_client].publish("lampe_led/5/set", settings.to_json)
    end
  end
end

