module TTT
  module Displayable
    ARROW         = ">>> "
    USER_ARROW    = "==> "
    EMPTY_MESSAGE = ""
    BLANK         = " "
    INDENT_DEPTH  = 4
    INDENT        = (BLANK * INDENT_DEPTH)

    def prompt(message, sign = ARROW)
      puts sign + message
    end

    def print_prompt(message, sign = ARROW)
      print sign + message
    end

    def announce_invalid_input
      prompt("This is not a valid choice!")
    end

    def please_press_enter
      prompt("Press enter to continue.")
      print_prompt(EMPTY_MESSAGE, INDENT)
      gets
    end

    def display_empty_user_prompt
      print_prompt(EMPTY_MESSAGE, USER_ARROW)
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
      string.split("\n").map { |line| INDENT + line }.join("\n")
    end
  end

  class Board
    include Displayable

    attr_reader :moves

    def initialize(x_color, o_color)
      @moves = []
      @x_color = x_color
      @o_color = o_color
    end

    def available_squares
      SQUARES.select { |square| not_yet_colored?(square) }
    end

    def add_move(square, color)
      moves << Move.new(square, color)
    end

    def add_random_move(color)
      add_move(available_squares.sample, color)
    end

    def add_reasonable_move(color)
      add_move(reasonable_square(color), color)
    end

    def add_optimal_move(color)
      add_move(nega_max(color, :top), color)
    end

    def draw
      clear_terminal
      puts "\n" + indent(board_as_string) + "\n\n"
    end

    def reset
      initialize(x_color, o_color)
    end

    def terminal?
      [x_color, o_color].any? { |color| winning_color?(color) } || full?
    end

    def find_winning_color
      [x_color, o_color].find { |color| winning_color?(color) }
    end

    private

    attr_reader :x_color, :o_color

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

    def other_color(color)
      color == x_color ? o_color : x_color
    end

    def winning_color?(color)
      WIN_LINES.any? { |line| line.all? { |square| to_h[square] == color } }
    end

    def full?
      available_squares.empty?
    end

    def board_as_string
      markers = SQUARES.map { |square| marker(square) }
      rows = markers.each_slice(SIZE).map do |row|
        BLANK + row.join(' | ') + BLANK
      end
      rows.join("\n-----------\n")
    end

    def marker(square)
      not_yet_colored?(square) ? BLANK : to_h[square]
    end

    def not_yet_colored?(square)
      to_h[square].nil?
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
      available_squares.select do |square|
        other_color = other_color(color)
        add_move(square, other_color)
        outcome = winning_color?(other_color)
        moves.pop
        outcome
      end
    end

    def nega_max(color, top = false, memo = {})
      unless memo[to_h]
        if terminal?
          memo[to_h] = payoff(color)
        else
          best = select_best(scored_options(color, memo))
          return best.first if top
          memo[to_h] = best.last
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
        add_move(square, color)
        value_for_square = -nega_max(other_color(color), false, memo)
        moves.pop
        [square, value_for_square]
      end
    end

    def select_best(options)
      options.max_by { |_, value_for_square| value_for_square }
    end

    def to_h
      moves.map(&:to_a).to_h
    end
  end

  class Player
    attr_reader :color

    def initialize(board, color)
      @board = board
      @color = color
    end

    private

    attr_reader :board
  end

  class Human < Player
    include Displayable

    def add_move
      square = square_chosen_by_user
      board.add_move(square, color)
    end

    def square_chosen_by_user
      square_chosen = nil
      loop do
        ask_to_choose_square
        display_empty_user_prompt
        square_chosen = gets.chomp.to_i
        break if board.available_squares.include?(square_chosen)
        announce_invalid_input
      end
      square_chosen
    end

    def ask_to_choose_square
      prompt("Please choose your square (#{joinor(board.available_squares)}).")
    end

    def to_s
      "you"
    end
  end

  class Computer < Player
    def initialize(board, color, skill_level)
      super(board, color)
      @skill_level = skill_level
    end

    def to_s
      "the Computer"
    end

    def add_move
      case skill_level
      when 1 then board.add_random_move(color)
      when 2 then board.add_reasonable_move(color)
      when 3 then board.add_optimal_move(color)
      end
    end

    private

    attr_reader :skill_level
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
      user_chooses_own_color
      set_computer_color
      user_chooses_start_color
      user_chooses_rounds_to_win
      user_chooses_skill_level
    end

    def display
      prompt("The current settings are as follows:")
      prompt("- You are the #{human_color}-player.", INDENT)
      prompt("- The computer is the #{computer_color}-player.", INDENT)
      prompt("- The #{start_color}-player begins.", INDENT)
      prompt("- The computer skill level is #{skill_level}.", INDENT)
      prompt("  (1: 'dumb', 2: 'smart', 3: 'very smart')", INDENT)
      prompt("- Winning a round is worth one point. If you score", INDENT)
      prompt("  #{rounds_to_win} point(s), you win the match.", INDENT)
    end

    private

    X_COLOR = 'X'
    O_COLOR = 'O'
    COMPUTER_SKILLS = [1, 2, 3]

    def colors
      [x_color, o_color]
    end

    def user_chooses_own_color
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

    def user_chooses_start_color
      color_chosen = nil
      loop do
        ask_to_choose_start_color
        color_chosen = gets.chomp.upcase
        break if colors.include?(color_chosen)
        announce_invalid_input
      end
      self.start_color = color_chosen
    end

    def user_chooses_skill_level
      level_chosen = nil
      loop do
        ask_to_choose_skill_level
        level_chosen = gets.chomp.to_i
        break if COMPUTER_SKILLS.include?(level_chosen)
        announce_invalid_input
      end
      self.skill_level = level_chosen
    end

    def user_chooses_rounds_to_win
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
      @board = Board.new(settings.x_color, settings.o_color)
      @human = Human.new(board, settings.human_color)
      @computer =
        Computer.new(board, settings.computer_color, settings.skill_level)
      @schedule = Schedule.new(human, computer, player(settings.start_color))
      @score_keeper = ScoreKeeper.new(settings.rounds_to_win)
    end

    def play
      loop do
        board.draw
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
      until board.terminal?
        schedule.active_player.add_move
        board.draw
        schedule.switch_active_player
      end
      evaluate_round
      present_round_results
    end

    def evaluate_round
      round_winner = player(board.find_winning_color)
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
      board.reset
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
      settings.display
      return unless user_wants_to_customize?
      settings.customize
      settings.display
      please_press_enter
    end

    def play
      Match.new(settings).play
      play if user_wants_rematch?
    end

    def outro
      prompt("Thanks for playing Tic Tac Toe! Goodbye!")
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

TTT::Game.new.start
