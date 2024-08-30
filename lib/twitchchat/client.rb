require 'socket'
require 'logger'

$stdout.sync = true

Thread.abort_on_exception = true

class TwitchChat
  class Client
    attr_reader :logger, :running, :socket

    def initialize(auth, logger: nil)
      @auth    = auth
      @logger  = logger || Logger.new('log/twitchchat.log')
      @running = false
      @socket  = nil
      @trivia = Trivia.new
    end

    def send(message)
      logger.info "< #{message}"
      socket.puts(message)
    end

    def listen
      connect
      @trivia.start

      sleep 3.seconds

      send("PRIVMSG #sophiediy :" + @trivia.current_question.prompt)
        Thread.start do
          while (running) do
            if !@trivia.playing?
              if @trivia.last_asked.last_asked_at < 5.seconds.ago
                @trivia.start
                send("PRIVMSG #sophiediy :" + @trivia.current_question.prompt)
              else
                next_question_in = 1.minute.ago - @trivia.last_asked.last_asked_at
                logger.info "Waiting for a new question... #{-next_question_in.round} seconds"
              end
            end
            sleep 1.seconds
          end
        end
        # $stdout.sync = true
        while (running) do
          ready = IO.select([socket])

          ready[0].each do |s|
            line    = s.gets.strip
            logger.info "> #{line}"
            interpret_line(line)
          end
        end
      # end
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

        process_content(message)

      end
    end

    def process_content(message)
      case
      when message.message.start_with?('!cheers') # && raw.match(/subscriber=1;/)
        match = message.message.match /;color=#(?<couleur>.{6});/
        send_rgb_color(match[:couleur].downcase)
      when message.message.start_with?('!led ')
        match = message.message.match /!led (?<couleur>.+)/
        puts match[:couleur]

        led(match[:couleur].downcase)
      else
        if @trivia.playing?
          if @trivia.check_answer(message.message, player: message.user)
            send("PRIVMSG #sophiediy :Bonne réponse! #{message.user} gagne un point et a maintenant #{Point.where(user: message.user).sum(:points)} points.")
          else
            logger.info "Mauvaise réponse de #{message.user}: #{message.message}"
          end
        end
      end
    end

    def led(color)
      colors = {
        "bleu" => {state: "ON", color: { r: 0, g: 0, b: 255}},
        "rouge" => {state: "ON", color: { r: 255, g: 0, b: 0}},
        "jaune" => {state: "ON", color: { r: 255, g: 255, b: 0}},
        "vert" => {state: "ON", color: { r: 0, g: 255, b: 0}},
        "violet" => {state: "ON", color: { r: 255, g: 0, b: 255}},
        "orange" => {state: "ON", color: { r: 255, g: 165, b: 0}},
        "cyan" => {state: "ON", color: { r: 0, g: 255, b: 255}},
        "blanc" => {state: "ON", color: { r: 255, g: 255, b: 255}},
        "rose" => {state: "ON", color: { r: 255, g: 64, b: 64}},
        "noir" => {state: "ON", color: { r: 0, g: 0, b: 0}},
      }

      effects = {
        "color waves" => {state: "ON", effect: "Color Waves"},
        "palette test" => {state: "ON", effect: "Palette Test"},
        "pride" => {state: "ON", effect: "Pride"},
        "rainbow with glitter" => {state: "ON", effect: "Rainbow With Glitter"},
        "confetti" => {state: "ON", effect: "Confetti"},
        "sinelon" => {state: "ON", effect: "Sinelon"},
        "juggle" => {state: "ON", effect: "Juggle"},
        "bpm" => {state: "ON", effect: "BPM"},
        "fire" => {state: "ON", effect: "Fire"},
        "solid color" => {state: "ON", effect: "Solid Color"},
      }
      text_responses = {
        "aide" => "Utilisez la commande !led avec une couleur ou un effet pour controller la lampe. Une couleur exadécimale fonctionne aussi. Exemples: !led bleu, !led rainbow, !led #EE4499",
        "couleurs" => "Les couleurs possibles en ce moment sont #{colors.keys.join(', ')}.",
        "effets" => "Les effets possibles en ce moment sont #{effects.keys.join(', ')}.",
      }

      states = effects.merge(colors)

      if states[color].present?
        send_mqtt(states[color])
      elsif text_responses[color].present?
        send("PRIVMSG #sophiediy :#{text_responses[color]}")
      elsif color.match? /^#[0-9A-F]+$/i
        send_rgb_color(color)
      else

        send("PRIVMSG #sophiediy :#{color} n'existe pas.")
      end
    end

    def send_rgb_color(color)
      r,g,b = color[1..6].chars.each_slice(2).to_a.map { |a| a.join.to_i(16) }
      send_mqtt({state: "ON", color: { r: r, g: g, b: b}})
    end

    def send_mqtt(settings)
      # Thread.current[:mqtt_client].publish("lampe_led/5/set", settings.to_json)
    end
  end
end
