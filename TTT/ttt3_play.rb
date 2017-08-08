module TTT
  module Displayable
    SIZE          = 3
    SQUARES       = (1..SIZE**2).to_a
    ARROW         = ">>> "
    USER_ARROW    = "==> "
    EMPTY_MESSAGE = ""
    BLANK         = " "
    INDENT_DEPTH  = 4
    INDENT        = (BLANK * INDENT_DEPTH)

    def prompt(message, sign = ARROW, cmd = :puts)
      send(cmd, sign + message)
    end

    def announce_invalid_input
      prompt("This is not a valid choice!")
    end

    def please_press_enter
      prompt("Press enter to continue.")
      prompt(EMPTY_MESSAGE, INDENT, :print)
      gets
    end

    def display_empty_user_prompt
      prompt(EMPTY_MESSAGE, USER_ARROW, :print)
    end

    def clear_terminal
      system 'clear'
    end

    def joinor(array_of_strings)
      case array_of_strings.size
      when 0 then ""
      when 1 then array_of_strings.first
      else
        array_of_strings[0..-2].join(", ") + " or #{array_of_strings[-1]}"
      end
    end

    def indent(string)
      string.split("\n").map { |line|  INDENT + line }.join("\n") << "\n"
    end
  end

  class Move
    attr_accessor :square, :color

    def initialize(square, color)
      @square = square
      @color = color
    end

    def to_a
      [square, color]
    end

    # def add_to(board) # this feels like a duplication
    #   board << self
    # end
  end

  class Position
    include Displayable

    MAX_LENGTH = SIZE * 3

    attr_reader :moves

    def initialize
      @moves = []
    end

    def <<(move)
      moves << move
    end

    def pop
      moves.pop
    end

    def available_squares
      SQUARES.select { |square| not_yet_chosen?(square) }
    end

    def draw
      clear_terminal
      puts indent(to_s)
    end

    def reset
      initialize
    end

    private

    def full?
      moves.length == MAX_LENGTH
    end

    def to_s
      markers = SQUARES.map { |square| marker(square) }
      rows = markers.each_slice(SIZE).map do |row|
        BLANK + row.join(' | ') + BLANK
      end
      "\n" + rows.join("\n-----------\n")
    end

    def marker(square)
      not_yet_chosen?(square) ? BLANK : to_h[square]
    end

    def not_yet_chosen?(square)
      to_h[square].nil?
    end

    def to_h
      moves.map(&:to_a).to_h
    end

  end

  class Options # belong to a player
    def initialize(board, color)
      @moves = available_squares.map { |square| Move.new(square, color) }
    end

    def select_at_random
      moves.sample
    end

    def select_reasonably

    end

    def select_best

    end
  end

  # in the main game loop:
  # square = options.choose_square
  # Move.new(square, color).add_to(history)

  class Analyzer

    attr_reader :history

    def initialize(history)
      @history = history
    end

  end

  class Player
    attr_reader :color

    def initialize(color)
      @color = color
    end
  end

  class Human < Player
    include Displayable

    def make_move(options)
      # todo: options is an Options object; code does not account for that
      square = square_chosen_by_user(options)
      board << Move.new(square, color)
    end

    def square_chosen_by_user(options)
      square_chosen = nil
      loop do
        ask_to_choose_square(options)
        display_empty_user_prompt
        square_chosen = gets.chomp.to_i
        break if options.include?(square)
        announce_invalid_input
      end
      square_chosen
    end

    def ask_to_choose_square(options)
      prompt("Please choose your square (#{joinor(options)}).")
    end

    def to_s
      "you"
    end
  end

  class Computer < Player
    def initialize(color, analyzer)
      super(color)
      @analyzer = analyzer
    end

    def to_s
      "the Computer"
    end

    def make_move(options)
      square = analyzer.select(options)
      board << Move.new(square, color)
    end
  end

  class Schedule
    attr_reader :active_player

    def initialize(player1, player2, first_to_move)
      @players = [player1, player2]
      @first_to_move = first_to_move
      @active_player = first_to_move
    end

    def switch_active_player
      self.active_player =
        (active_player == players.first ? players.last : players.first)
    end

    def reset
      initialize(*players, first_to_move)
    end

    private

    attr_reader :players, :first_to_move
    attr_writer :active_player
  end

  class ScoreKeeper
    attr_reader :round_winner, :match_winner

    def initialize(rounds_to_win)
      @scores = Hash.new { |hash, key| hash[key] = 0 }
      @round_winner = nil
      @match_winner = nil
      @rounds_to_win = rounds_to_win
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

    attr_accessor :scores
    attr_writer   :round_winner, :match_winner
    attr_reader   :rounds_to_win

    def match_winner?(player)
      scores[player] == rounds_to_win
    end
  end

  class Settings
    include Displayable

    attr_accessor :x_color, :o_color, :colors, :human_color, :computer_color,
                  :rounds_to_win, :skill_level, :start_color

    def initialize
      @x_color = X_COLOR
      @o_color = O_COLOR
      @human_color    = x_color
      @computer_color = o_color
      @start_color = x_color
      @rounds_to_win  = 3
      @skill_level    = 2
    end

    def customize
      let_user_choose_own_color
      set_computer_color
      let_user_choose_start_color
      let_user_choose_rounds_to_win
      let_user_choose_skill_level
    end

    private

    X_COLOR = 'X'
    O_COLOR = 'O'
    COMPUTER_SKILLS = [1, 2, 3]

    def colors
      [x_color, o_color]
    end

    def let_user_choose_own_color
      color = nil
      loop do
        ask_to_choose_own_color
        color = gets.chomp.upcase
        break if colors.include?(color)
        announce_invalid_input
      end
      self.human_color = color
    end

    def set_computer_color
      self.computer_color =
        (human_color == colors.first ? colors.last : colors.first)
    end

    def let_user_choose_start_color
      color_chosen = nil
      loop do
        ask_to_choose_start_color
        color_chosen = gets.chomp.upcase
        break if colors.include?(color_chosen)
        announce_invalid_input
      end
      self.start_color = color_chosen
    end

    def let_user_choose_skill_level
      level_chosen = nil
      loop do
        ask_to_choose_skill_level
        level_chosen = gets.chomp.to_i
        break if COMPUTER_SKILLS.include?(level_chosen)
        announce_invalid_input
      end
      self.skill_level = level_chosen
    end

    def let_user_choose_rounds_to_win
      number = nil
      loop do
        ask_to_choose_rounds_to_win
        number = gets.chomp
        break if number.to_i.to_s == number && number.to_i > 0
        announce_invalid_input
      end
      self.rounds_to_win = number.to_i
    end

    def ask_to_choose_own_color
      prompt("Please choose your color (#{joinor(colors)}).")
      display_empty_user_prompt
    end

    def ask_to_choose_rounds_to_win
      prompt("Choose the number of point(s) necessary to win the match.")
      display_empty_user_prompt
    end

    def ask_to_choose_skill_level
      prompt("Please choose the skill level of your opponent (1, 2 or 3).")
      prompt("Level 1: dumb; level 2: smart; level 3: very smart.", INDENT)
      display_empty_user_prompt
    end

    def ask_to_choose_start_color
      prompt("Which player would you like to start? (#{joinor(colors)})")
      display_empty_user_prompt
    end
  end

  class Match
    include Displayable

    def initialize(settings)
      @board = Board.new
      @human = Human.new(settings.human_color)
      @computer =
        Computer.new(settings.computer_color, settings.skill_level)
      @schedule = Schedule.new(human, computer, player(settings.start_color))
      @score_keeper = ScoreKeeper.new(settings.rounds_to_win)
    end

    def play
      loop do
        board.draw # draw the board
        play_round
        break if score_keeper.match_winner
        reset_for_next_round
      end
      present_match_winner
    end

    private

    attr_reader :board, :human, :computer, :schedule, :score_keeper

    def player(color)
      { human.color => human, computer.color => computer }[color]
    end

    def play_round
      until board.terminal? # BOARD: do we have a terminal board?
        schedule.active_player.make_move(board) # BOARD-dependent: make a move
        board.draw # BOARD: draw the board
        schedule.switch_active_player
      end
      evaluate_round
      present_round_results
    end

    def evaluate_round
      round_winner = player(board.find_winning_color) # BOARD: what is the winning color? (if any)
      score_keeper.keep_score(round_winner)
    end

    def present_round_results
      round_winner = score_keeper.round_winner

      if round_winner
        prompt("This round goes to #{round_winner}.")
      else
        prompt("This round is a tie.")
      end

      prompt("You have #{score_keeper[human]} point(s).")
      prompt("The Computer has #{score_keeper[computer]} point(s).", INDENT)
    end

    def reset_for_next_round
      board.reset # reset the board.
      schedule.reset
      please_press_enter
    end

    def present_match_winner
      prompt("The match winner is ... #{score_keeper.match_winner}!!")
    end
  end

  class Game
    include Displayable

    def initialize
      @settings = Settings.new
    end

    def start
      intro
      customize
      play
      outro
    end

    private

    attr_reader :settings

    def intro
      clear_terminal
      prompt("Welcome to Tic Tac Toe!")
    end

    def customize
      display_settings
      return unless user_wants_to_customize?
      settings.customize
      display_settings
      please_press_enter
    end

    def play
      Match.new(settings).play
      play if user_wants_rematch?
    end

    def outro
      prompt("Thanks for playing Tic Tac Toe! Goodbye!")
    end

    def display_settings
      prompt("The current settings are as follows:")
      prompt("- You are the #{settings.human_color}-player.", INDENT)
      prompt("- The computer is the #{settings.computer_color}-player.", INDENT)
      prompt("- The #{settings.start_color}-player begins.", INDENT)
      prompt("- The computer skill level is #{settings.skill_level}.", INDENT)
      prompt("  (1: 'dumb', 2: 'smart', 3: 'very smart')", INDENT)
      prompt("- Winning a round is worth one point. If you score", INDENT)
      prompt("  #{settings.rounds_to_win} point(s), you win the match.", INDENT)
    end

    def user_wants_to_customize?
      answer = nil
      loop do
        ask_to_customize
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        announce_invalid_input
      end
      answer.start_with?('y')
    end

    def ask_to_customize
      prompt("Would you like to customize these settings? (y/n)")
      display_empty_user_prompt
    end

    def user_wants_rematch?
      answer = nil
      loop do
        ask_for_rematch
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        announce_invalid_input
      end
      answer.start_with?('y')
    end

    def ask_for_rematch
      prompt("Would you like to play again? (y/n)")
      display_empty_user_prompt
    end
  end
end

# TTT::Game.new.start

TTT::Position.new.draw
