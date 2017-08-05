module TTT
  module Customizable
    AI = :smart        # :smart or :dumb
    ROUNDS_TO_WIN = 2  # any positive integer
  end

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

  module Message
    include Customizable, Utils

    def self.prompt(message)
      puts '--> ' + message
    end

    def self.welcome
      prompt("Welcome to Tic Tac Toe!")
      prompt("The first player to win #{ROUNDS_TO_WIN} rounds wins the match.")
      prompt("You are the X-player.")
    end

    def self.announce_invalid_input
      prompt("This is not a valid choice!")
    end

    def self.present_round_winner(winner)
      if winner
        prompt("This round goes to #{winner}.")
      else
        prompt("This round is a tie.")
      end
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

  module GetInput
    include Utils

    def self.hit_enter
      Message.press_enter
      gets
    end

    def self.rematch?
      answer = nil
      loop do
        Message.want_to_play_again
        answer = gets.chomp
        break if answer.start_with?('y', 'n')
        Message.announce_invalid_input
      end
      answer.start_with?('y')
    end

    def self.choose_move(options)
      square = nil
      loop do
        Message.please_choose(Utils.joinor(options))
        square = gets.chomp.to_i
        break if options.include?(square)
        Message.announce_invalid_input
      end
      square
    end
  end

  class Move
    attr_reader :square, :color

    def initialize(square, color)
      @square = square
      @color = color
    end

    def to_a
      [square, color]
    end
  end

  class GameBoard
    include Utils

    COLOR1 = 'X'
    COLOR2 = 'O'
    SIZE = 3
    SQUARES = (1..SIZE**2)
    WIN_LINES = [
      [1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
      [1, 4, 7], [2, 5, 8], [3, 6, 9], # cols
      [1, 5, 9], [3, 5, 7]             # diags
    ]

    attr_reader :moves, :human_color, :computer_color, :colors

    def initialize
      @moves = []
      @human_color = COLOR1
      @computer_color = COLOR2
      @colors = [human_color, computer_color]
    end

    def <<(move)
      moves << move
    end

    def to_h
      @moves.map(&:to_a).to_h
    end

    def other_color(color)
      color == computer_color ? human_color : computer_color
    end

    def find_winning_color
      colors.find { |color| winning_color?(color) }
    end

    def available_squares
      SQUARES.select { |square| empty?(square) }
    end

    def winning_color?(color)
      WIN_LINES.any? { |line| line.all? { |square| to_h[square] == color } }
    end

    def terminal?
      colors.any? { |color| winning_color?(color) } || full?
    end

    def reset
      initialize
    end

    def draw
      Utils.clear
      puts board_string
    end

    private

    def board_string
      color_sequence = SQUARES.map { |square| color(square) }
      rows = color_sequence.each_slice(SIZE).map do |row|
        " " + row.join(' | ') + " "
      end
      "\n" + rows.join("\n-----------\n") + "\n" * 2
    end

    def color(square)
      empty?(square) ? " " : to_h[square]
    end

    def empty?(square)
      to_h[square].nil?
    end

    def full?
      available_squares.empty?
    end
  end

  class Player
    attr_reader :board, :color

    def initialize(board)
      @board = board
      @color = nil
    end
  end

  class Human < Player
    def initialize(board)
      super
      @color = board.human_color
    end

    def choose
      square = GetInput.choose_move(board.available_squares)
      board << Move.new(square, color)
    end

    def to_s
      "you"
    end
  end

  class Computer < Player
    include Customizable

    def initialize(board)
      super
      @color = board.computer_color
    end

    def choose
      AI == :dumb ? choose_randomly : choose_optimally
    end

    def to_s
      "the Computer"
    end

    private

    def choose_randomly
      board << Move.new(board.available_squares.sample, color)
    end

    def choose_optimally
      board << Move.new(nega_max(color, :top), color)
    end

    def nega_max(color, top = false, memo = {})
      unless memo[board.to_h]
        if board.terminal?
          memo[board.to_h] = payoff(color)
        else
          best = select_best(scored_options(color, memo))
          top ? (return best.first) : memo[board.to_h] = best.last
        end
      end
      memo[board.to_h]
    end

    def payoff(color)
      if board.winning_color?(color)
        1
      elsif board.winning_color?(board.other_color(color))
        -1
      else
        0
      end
    end

    def scored_options(color, memo)
      board.available_squares.map do |square|
        board.moves << Move.new(square, color)
        value_for_square = -nega_max(board.other_color(color), false, memo)
        board.moves.pop
        [square, value_for_square]
      end
    end

    def select_best(options)
      options.max_by { |_, value_for_square| value_for_square }
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
    include Customizable

    attr_accessor :scores, :round_winner, :match_winner

    def initialize
      @scores = Hash.new { |hash, key| hash[key] = 0 }
      @round_winner = nil
      @match_winner = nil
    end

    def keep_score(round_winner)
      self.round_winner = round_winner
      scores[round_winner] += 1
      self.match_winner = round_winner if match_winner?(round_winner)
    end

    def [](player)
      scores[player]
    end

    def []=(player, value)
      scores[player] = value
    end

    def match_winner?(player)
      scores[player] == ROUNDS_TO_WIN
    end
  end

  class Game
    def start
      Utils.clear
      Message.welcome
      GetInput.hit_enter
      play
      Message.goodbye
    end

    private

    attr_reader :board, :human, :computer, :schedule, :score_keeper

    def play
      init_match
      loop do
        board.draw
        play_round
        break if score_keeper.match_winner
        GetInput.hit_enter
        reset
      end
      Message.present_match_winner(score_keeper.match_winner)
      play if GetInput.rematch?
    end

    def init_match
      @board = GameBoard.new
      @human = Human.new(board)
      @computer = Computer.new(board)
      @schedule = Schedule.new(human, computer)
      @score_keeper = ScoreKeeper.new
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
      converter = { human.color => human, computer.color => computer }
      converter[color]
    end

    def present_round_results
      Message.present_round_winner(score_keeper.round_winner)
      Message.present_scores(score_keeper[human], score_keeper[computer])
    end

    def reset
      board.reset
      schedule.reset
    end
  end
end

TTT::Game.new.start
