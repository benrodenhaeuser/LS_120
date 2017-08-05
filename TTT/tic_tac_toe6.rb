# A *move* is a colored square [square, color].
# A *board* records moves made.
# A *player* chooses moves (according to its subclass).
# A *schedule* keeps track of who gets to move.
# A *score_keeper* keeps track of round wins so far.

module TTT
  module Utils
    def self.clear
      system 'clear'
    end

    def self.joinor(array)
      case array.size
      when 0 then ''
      when 1 then array.first
      else
        array[0..-2].join(', ') + " or #{array[-1]}"
      end
    end
  end

  module MessageToUser
    def self.prompt(message)
      puts '--> ' + message
    end

    def self.welcome
      prompt("Welcome to Tic Tac Toe!")
    end

    def self.choose_color
      prompt("Please choose your color (X or O).")
    end

    def self.acknowledge_color(color)
      prompt("You have chosen to be the #{color}-player.")
    end

    def self.choose_rounds
      prompt("Choose the number of round wins necessary to win the match.")
    end

    def self.acknowledge_number_of_rounds(number)
      prompt("The first player to win #{number} rounds wins the match.")
    end

    def self.choose_difficulty
      prompt("Please choose the skill level of your opponent (1, 2 or 3).")
      prompt("Level 1: dumb; level 2: intermediate; level 3: very smart.")
    end

    def self.acknowledge_difficulty(number)
      prompt("You will play against a level #{number} opponent.")
    end

    def self.announce_invalid_input
      prompt("This is not a valid choice!")
    end

    def self.present_round_winner(winner)
      prompt("This round goes to #{winner}.")
    end

    def self.announce_tie
      prompt("This round is a tie.")
    end

    def self.present_scores(human_score, computer_score)
      prompt("You have #{human_score} point(s).")
      prompt("The Computer has #{computer_score} point(s).")
    end

    def self.present_match_winner(match_winner)
      prompt("We have a match winner: it's #{match_winner}.")
    end

    def self.goodbye
      prompt("Thanks for playing Tic Tac Toe! Goodbye!")
    end

    def self.press_enter
      prompt("Press enter to continue.")
    end

    def self.want_to_play_again
      prompt("Would you like to play again? (y/n)")
    end

    def self.please_choose(options_string)
      prompt("Please choose your square (#{options_string}).")
    end
  end

  module GetUserInput
    def self.press_enter
      MessageToUser.press_enter
      gets
    end

    def self.choose_human_color
      color = nil
      loop do
        MessageToUser.choose_color
        color = gets.chomp.upcase
        break if ['X', 'O'].include?(color) # todo: extract somehow
        MessageToUser.announce_invalid_input
      end
      MessageToUser.acknowledge_color(color)
      GetUserInput.press_enter
      color
    end

    def self.choose_difficulty
      level_chosen = nil
      loop do
        MessageToUser.choose_difficulty
        level_chosen = gets.chomp.to_i
        break if [1, 2, 3].include?(level_chosen) # todo: extract somehow
        MessageToUser.announce_invalid_input
      end
      MessageToUser.acknowledge_difficulty(level_chosen)
      GetUserInput.press_enter
      level_chosen
    end

    def self.choose_number_of_rounds
      number = nil
      loop do
        MessageToUser.choose_rounds
        number = gets.chomp
        break if number.to_i.to_s == number
        MessageToUser.announce_invalid_input
      end
      MessageToUser.acknowledge_number_of_rounds(number)
      GetUserInput.press_enter
      number.to_i
    end

    def self.rematch?
      answer = nil
      loop do
        MessageToUser.want_to_play_again
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        MessageToUser.announce_invalid_input
      end
      answer.start_with?('y')
    end

    def self.choose_square(options)
      square = nil
      loop do
        MessageToUser.please_choose(Utils.joinor(options))
        square = gets.chomp.to_i
        break if options.include?(square)
        MessageToUser.announce_invalid_input
      end
      square
    end
  end

  class GameBoard
    attr_reader :moves, :x_color, :o_color

    def initialize
      @moves = []
      @x_color = 'X'
      @o_color = 'O'
    end

    def available_squares
      SQUARES.select { |square| empty?(square) }
    end

    def add_move(square, color)
      moves << Move.new(square, color)
    end

    def add_random_move(color)
      moves << Move.new(available_squares.sample, color)
    end

    def add_reasonably_smart_move(color)
      moves << Move.new(reasonable_square(color), color)
    end

    def add_optimal_move(color)
      moves << Move.new(nega_max(color, :top), color)
    end

    def other_color(color)
      color == x_color ? o_color : x_color
    end

    def terminal?
      colors.any? { |color| winning_color?(color) } || full?
    end

    def find_winning_color
      colors.find { |color| winning_color?(color) }
    end

    def draw
      Utils.clear
      puts board_as_string
    end

    def reset
      initialize
    end

    private

    SIZE = 3
    SQUARES = (1..SIZE**2)
    CENTER_SQUARE = 5
    WIN_LINES = [
      [1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
      [1, 4, 7], [2, 5, 8], [3, 6, 9], # cols
      [1, 5, 9], [3, 5, 7]             # diags
    ]

    Move = Struct.new(:square, :color) do
      def to_a
        [square, color]
      end
    end

    def winning_color?(color)
      WIN_LINES.any? { |line| line.all? { |square| to_h[square] == color } }
    end

    def to_h
      @moves.map(&:to_a).to_h
    end

    def colors
      [x_color, o_color]
    end

    def board_as_string
      markers = SQUARES.map { |square| marker(square) }
      rows = markers.each_slice(SIZE).map do |row|
        " " + row.join(' | ') + " "
      end
      "\n" + rows.join("\n-----------\n") + "\n" * 2
    end

    def marker(square)
      empty?(square) ? " " : to_h[square]
    end

    def empty?(square)
      to_h[square].nil?
    end

    def full?
      available_squares.empty?
    end

    def reasonable_square(color)
      other_color = other_color(color)
      threats_for_color = threats_for(color)
      threats_for_other_color = threats_for(other_color)

      reasonable_squares =
        if !threats_for_other_color.empty?
          threats_for_other_color
        elsif !threats_for_color.empty?
          threats_for_color
        elsif available_squares.include?(CENTER_SQUARE)
          [CENTER_SQUARE]
        else
          available_squares
        end

      reasonable_squares.sample
    end

    def threats_for(color)
      available_squares.select { |square| threat_for?(color, square) }
    end

    def threat_for?(color, square)
      other_color = other_color(color)
      moves << Move.new(square, other_color)
      outcome = winning_color?(other_color)
      moves.pop
      outcome
    end

    def nega_max(color, top = false, memo = {})
      unless memo[to_h]
        if terminal?
          memo[to_h] = payoff(color)
        else
          best = select_best(scored_options(color, memo))
          top ? (return best.first) : memo[to_h] = best.last
        end
      end
      memo[to_h]
    end

    def payoff(color)
      if winning_color?(color)
        1
      elsif winning_color?(other_color(color))
        -1
      else
        0
      end
    end

    def scored_options(color, memo)
      available_squares.map do |square|
        moves << Move.new(square, color)
        value_for_square = -nega_max(other_color(color), false, memo)
        moves.pop
        [square, value_for_square]
      end
    end

    def select_best(options)
      options.max_by { |_, value_for_square| value_for_square }
    end
  end

  class Player
    attr_reader :board, :color

    def initialize(board, color)
      @board = board
      @color = color
    end
  end

  class Human < Player
    def choose
      square = GetUserInput.choose_square(board.available_squares)
      board.add_move(square, color)
    end

    def to_s
      "you"
    end
  end

  class Computer < Player
    def to_s
      "the Computer"
    end
  end

  class DumbComputer < Computer
    def choose
      board.add_random_move(color)
    end
  end

  class ReasonablySmartComputer < Computer
    def choose
      board.add_reasonably_smart_move(color)
    end
  end

  class VerySmartComputer < Computer
    def choose
      board.add_optimal_move(color)
    end
  end

  class Schedule
    attr_reader :players
    attr_accessor :active_player

    def initialize(human, computer)
      @players = [human, computer]
      @active_player = human
    end

    def switch_active_player
      self.active_player =
        (active_player == players.first ? players.last : players.first)
    end

    def reset
      initialize(*players)
    end
  end

  class ScoreKeeper
    attr_accessor :scores, :round_winner, :match_winner
    attr_reader :number_of_rounds

    def initialize(number_of_rounds)
      @scores = Hash.new { |hash, key| hash[key] = 0 }
      @round_winner = nil
      @match_winner = nil
      @number_of_rounds = number_of_rounds
    end

    def keep_score(round_winner)
      self.round_winner = round_winner
      scores[round_winner] += 1
      self.match_winner = round_winner if match_winner?(round_winner)
    end

    def [](player)
      scores[player]
    end

    private

    def match_winner?(player)
      scores[player] == number_of_rounds
    end
  end

  class Game
    def initialize
      @board = GameBoard.new
    end

    def start
      intro
      configure
      play
      outro
    end

    private

    attr_reader :board, :human, :computer, :schedule, :score_keeper
    attr_accessor :difficulty, :number_of_rounds, :human_color, :computer_color

    def intro
      Utils.clear
      MessageToUser.welcome
    end

    def configure
      self.human_color = GetUserInput.choose_human_color
      self.computer_color = board.other_color(human_color)
      self.number_of_rounds = GetUserInput.choose_number_of_rounds
      self.difficulty = GetUserInput.choose_difficulty
    end

    def play
      init_match
      loop do
        board.draw
        play_round
        break if score_keeper.match_winner
        GetUserInput.press_enter
        reset
      end
      MessageToUser.present_match_winner(score_keeper.match_winner)
      play if GetUserInput.rematch?
    end

    def init_match
      @human = Human.new(board, human_color)
      create_computer_player
      @schedule = Schedule.new(human, computer)
      @score_keeper = ScoreKeeper.new(number_of_rounds)
    end

    def create_computer_player
      @computer = case difficulty
                  when 1 then DumbComputer.new(board, computer_color)
                  when 2 then ReasonablySmartComputer.new(board, computer_color)
                  when 3 then VerySmartComputer.new(board, computer_color)
                  end
    end

    def play_round
      until board.terminal?
        schedule.active_player.choose
        board.draw
        schedule.switch_active_player
      end
      evaluate_round
      present_round_results
    end

    def evaluate_round
      round_winner = color_to_player(board.find_winning_color)
      score_keeper.keep_score(round_winner)
    end

    def color_to_player(color)
      { human_color => human, computer_color => computer }[color]
    end

    def present_round_results
      round_winner = score_keeper.round_winner
      if round_winner
        MessageToUser.present_round_winner(round_winner)
      else
        MessageToUser.announce_tie
      end
      MessageToUser.present_scores(score_keeper[human], score_keeper[computer])
    end

    def reset
      board.reset
      schedule.reset
    end

    def outro
      MessageToUser.goodbye
    end
  end
end

TTT::Game.new.start
