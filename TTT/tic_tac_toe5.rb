# A *move* is a colored square [square, color]
# A *board* records moves made
# A *player* chooses moves
# A *schedule* keeps track of who gets to move
# A *score_keeper* keeps track of round wins so far

# main problem: *a player needs a board to make her choices*
# solution: keep the interface of the board small. but then, why use the player
# at all?


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

    def self.choose_rounds
      prompt("Choose the number of round wins to win the match.")
      prompt("Any number greater than 0 will do.")
    end

    def self.acknowledge_number_of_rounds(number)
      prompt("The first player to win #{number} rounds wins the match.")
    end

    def self.choose_difficulty
      prompt("Choose the skill level of your opponent (1, 2 or 3).")
      prompt("Level 1: dumb; level 2: intermediate; level 3: very smart.")
    end

    def self.acknowledge_difficulty_level(number)
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
    def self.hit_enter
      MessageToUser.press_enter
      gets
    end

    def self.choose_difficulty_level
      level_chosen = nil
      loop do
        MessageToUser.choose_difficulty
        level_chosen = gets.chomp.to_i
        break if [1, 2, 3].include?(level_chosen)
        MessageToUser.announce_invalid_input
      end
      MessageToUser.acknowledge_difficulty_level(level_chosen)
      self.hit_enter
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
      self.hit_enter
      number.to_i
    end

    def self.rematch?
      answer = nil
      loop do
        MessageToUser.want_to_play_again
        answer = gets.chomp
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
      # todo: board should just have two colors, I guess
      @colors = [human_color, computer_color]
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

    def terminal?
      colors.any? { |color| winning_color?(color) } || full?
    end

    def reset
      initialize
    end

    def draw
      Utils.clear
      puts board_as_string
    end

    # todo: should be private
    def <<(move)
      moves << move
    end

    # todo: should be private
    def winning_color?(color)
      WIN_LINES.any? { |line| line.all? { |square| to_h[square] == color } }
    end

    # todo: should be private
    def to_h
      @moves.map(&:to_a).to_h
    end

    private

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
      @color = board.human_color # todo: the board should not know this
    end

    def choose
      square = GetUserInput.choose_square(board.available_squares)
      board << Move.new(square, color) # todo: board.add_move(square, color)
    end

    def to_s
      "you"
    end
  end

  class Computer < Player
    def initialize(board)
      super
      @color = board.computer_color # todo: the board should not know this
    end

    def to_s
      "the Computer"
    end
  end

  class DumbComputer < Computer
    def choose
      board << Move.new(board.available_squares.sample, color)
      # todo: board.add_random_move(color)
    end
  end

  class ReasonablySmartComputer < Computer
    def choose
      board << Move.new(reasonable_square, color)
      # todo: board.add_reasonable_move(color)
    end

    private # all of the following methods should be part of Board class

    CENTER_SQUARE = 5

    def reasonable_square
      other_color = board.other_color(color)
      threats_for_color = threats_for(color)
      threats_for_other_color = threats_for(other_color)

      if !threats_for_other_color.empty?
        threats_for_other_color
      elsif !threats_for_color.empty?
        threats_for_color
      elsif board.available_squares.include?(CENTER_SQUARE)
        [CENTER_SQUARE]
      else
        board.available_squares
      end.sample
    end

    def threats_for(color)
      board.available_squares.select { |square| threat_for?(color, square) }
    end

    def threat_for?(color, square)
      other_color = board.other_color(color)
      board << Move.new(square, other_color)
      outcome = board.winning_color?(other_color)
      board.moves.pop
      outcome
    end
  end

  class VerySmartComputer < Computer
    def choose
      board << Move.new(nega_max(color, :top), color)
      # todo: board.add_optimal_move(color)
    end

    private # all of the following methods should be part of Board class

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

    def []=(player, value)
      scores[player] = value
    end

    def match_winner?(player)
      scores[player] == number_of_rounds
    end
  end

  class Game
    attr_accessor :difficulty_level, :number_of_rounds

    def start
      intro
      configure
      play
      outro
    end

    private

    attr_reader :board, :human, :computer, :schedule, :score_keeper

    def intro
      Utils.clear
      MessageToUser.welcome
    end

    def configure
      # user_chooses_color # todo
      self.number_of_rounds = GetUserInput.choose_number_of_rounds
      self.difficulty_level = GetUserInput.choose_difficulty_level
    end

    def play
      init_match
      loop do
        board.draw
        play_round
        break if score_keeper.match_winner
        GetUserInput.hit_enter
        reset
      end
      MessageToUser.present_match_winner(score_keeper.match_winner)
      play if GetUserInput.rematch?
    end

    def init_match
      @board = GameBoard.new
      @human = Human.new(board)
      create_computer_player
      @schedule = Schedule.new(human, computer)
      @score_keeper = ScoreKeeper.new(number_of_rounds)
    end

    def create_computer_player
      case difficulty_level
      when 1 then @computer = DumbComputer.new(board)
      when 2 then @computer = ReasonablySmartComputer.new(board)
      when 3 then @computer = VerySmartComputer.new(board)
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
      converter = { human.color => human, computer.color => computer }
      converter[color]
    end

    def present_round_results
      if score_keeper.round_winner
        MessageToUser.present_round_winner(score_keeper.round_winner)
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
