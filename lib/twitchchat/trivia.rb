class TwitchChat
  class Trivia

    attr_reader :current_question, :last_asked

    def initialize
      @current_question = nil
      @last_asked = nil
    end

    def start
      pick_question
    end

    def stop
      @last_asked = @current_question
      @current_question = nil
    end

    def check_answer(answer, player:)
      return unless playing?
      if answer.downcase == current_question.answer.downcase
        Point.create(user: player, question: current_question, points: 1)
        stop
        return true
      end
      false
    end

    def playing?
      current_question.present?
    end

    private

    def pick_question
      @current_question = Question.where(last_asked_at: ..1.day.ago).or(Question.where(nil)).order('RANDOM()').first
      @current_question.update(last_asked_at: Time.now)
    end
  end
end
