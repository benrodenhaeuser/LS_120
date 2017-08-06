module TTT
  module DisplayConstants
    ARROW         = ">>> "
    USER_ARROW    = "==> "
    EMPTY_MESSAGE = ""
    BLANK         = " "
    INDENT_DEPTH  = 4
    INDENT        = (BLANK * INDENT_DEPTH)
  end

  module Utils
    include DisplayConstants

    def self.clear_terminal
      system 'clear'
    end

    def self.joinor(array_of_strings)
      case array_of_strings.size
      when 0 then ""
      when 1 then array_of_strings.first
      else
        array_of_strings[0..-2].join(", ") + " or #{array_of_strings[-1]}"
      end
    end

    def self.indent(string)
      lines = string.split("\n")
      indented_string = INDENT
      lines.each do |line|
        indented_string += (line + "\n")
        indented_string += INDENT
      end
      indented_string
    end
  end

  module MessageToUser
    include DisplayConstants

    def self.prompt(message, sign = ARROW, cmd = :puts)
      send(cmd, sign + message)
    end

    def self.welcome
      Utils.clear_terminal
      prompt("Welcome to Tic Tac Toe!")
    end

    def self.display_settings(args)
      prompt("The current settings are as follows:")
      prompt("- You are the #{args[:human_color]}-player.", INDENT)
      prompt("- The computer is the #{args[:computer_color]}-player.", INDENT)
      prompt("- The #{args[:start_color]}-player kicks off each round.", INDENT)
      prompt("- The computer skill level is #{args[:skill_level]}.", INDENT)
      prompt("  (1: 'dumb', 2: 'smart', 3: 'very smart')", INDENT)
      prompt("- Winning a round gives you one point. If you score", INDENT)
      prompt("  #{args[:rounds_to_win]} point(s), you win the match.", INDENT)
    end

    def self.want_to_customize
      prompt("Would you like to customize these settings? (y/n)")
    end

    def self.choose_color(colors_string)
      prompt("Please choose your color (#{colors_string}).")
    end

    def self.choose_rounds_to_win
      prompt("Choose the number of point(s) necessary to win the match.")
    end

    def self.choose_skill_level
      prompt("Please choose the skill level of your opponent (1, 2 or 3).")
      prompt("Level 1: dumb; level 2: smart; level 3: very smart.", INDENT)
    end

    def self.choose_start_color(colors_string)
      prompt("Which player would you like to start? (#{colors_string})")
    end

    def self.announce_invalid_input
      prompt("This is not a valid choice!")
    end

    def self.choose_square(options_string)
      prompt("Please choose your square (#{options_string}).")
    end

    def self.present_round_winner(winner)
      prompt("This round goes to #{winner}.")
    end

    def self.announce_tie
      prompt("This round is a tie.")
    end

    def self.present_scores(human_score, computer_score)
      prompt("You have #{human_score} point(s).")
      prompt("The Computer has #{computer_score} point(s).", INDENT)
    end

    def self.present_match_winner(match_winner)
      prompt("The match winner is ... #{match_winner}!!")
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
  end

  module GetUserInput
    include DisplayConstants

    def self.press_enter
      MessageToUser.press_enter
      MessageToUser.prompt(EMPTY_MESSAGE, INDENT, :print)
      gets
    end

    def self.customize?
      answer = nil
      loop do
        MessageToUser.want_to_customize
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        MessageToUser.announce_invalid_input
      end
      answer.start_with?('y')
    end

    def self.choose_human_color(colors)
      color = nil
      loop do
        MessageToUser.choose_color(Utils.joinor(colors))
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        color = gets.chomp.upcase
        break if colors.include?(color)
        MessageToUser.announce_invalid_input
      end
      color
    end

    def self.choose_skill_level(levels)
      level_chosen = nil
      loop do
        MessageToUser.choose_skill_level
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        level_chosen = gets.chomp.to_i
        break if levels.include?(level_chosen)
        MessageToUser.announce_invalid_input
      end
      level_chosen
    end

    def self.choose_rounds_to_win
      number = nil
      loop do
        MessageToUser.choose_rounds_to_win
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        number = gets.chomp
        break if number.to_i.to_s == number && number.to_i > 0
        MessageToUser.announce_invalid_input
      end
      number.to_i
    end

    def self.choose_start_color(colors)
      color_chosen = nil
      loop do
        MessageToUser.choose_start_color(Utils.joinor(colors))
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        color_chosen = gets.chomp.upcase
        break if colors.include?(color_chosen)
        MessageToUser.announce_invalid_input
      end
      color_chosen
    end

    def self.rematch?
      answer = nil
      loop do
        MessageToUser.want_to_play_again
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        MessageToUser.announce_invalid_input
      end
      answer.start_with?('y')
    end

    def self.choose_square(options)
      square = nil
      loop do
        MessageToUser.choose_square(Utils.joinor(options))
        MessageToUser.prompt(EMPTY_MESSAGE, USER_ARROW, :print)
        square = gets.chomp.to_i
        break if options.include?(square)
        MessageToUser.announce_invalid_input
      end
      square
    end
  end

  class Board
    include DisplayConstants

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
      moves << Move.new(available_squares.sample, color)
    end

    def add_reasonably_smart_move(color)
      moves << Move.new(reasonable_square(color), color)
    end

    def add_optimal_move(color)
      moves << Move.new(nega_max(color, :top), color)
    end

    def terminal?
      [x_color, o_color].any? { |color| winning_color?(color) } || full?
    end

    def find_winning_color
      [x_color, o_color].find { |color| winning_color?(color) }
    end

    def draw
      Utils.clear_terminal
      puts Utils.indent(board_as_string)
    end

    def reset
      initialize(x_color, o_color)
    end

    private

    attr_reader :moves, :x_color, :o_color

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

    def full?
      available_squares.empty?
    end

    def other_color(color)
      color == x_color ? o_color : x_color
    end

    def to_h
      @moves.map(&:to_a).to_h
    end

    def board_as_string
      markers = SQUARES.map { |square| marker(square) }
      rows = markers.each_slice(SIZE).map do |row|
        BLANK + row.join(' | ') + BLANK
      end
      "\n" + rows.join("\n-----------\n")
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
    attr_reader :color

    def initialize(board, color)
      @board = board
      @color = color
    end

    private

    attr_reader :board
  end

  class Human < Player
    def choose_square
      square = GetUserInput.choose_square(board.available_squares)
      board.add_move(square, color)
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

    def choose_square
      case skill_level
      when 1 then board.add_random_move(color)
      when 2 then board.add_reasonably_smart_move(color)
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
    X_COLOR = 'X'
    O_COLOR = 'O'
    COMPUTER_SKILLS = [1, 2, 3]

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

    def colors
      [x_color, o_color]
    end

    def customize
      self.human_color = GetUserInput.choose_human_color(colors)
      self.computer_color =
        (human_color == colors.first ? colors.last : colors.first)
      self.start_color = GetUserInput.choose_start_color(colors)
      self.rounds_to_win = GetUserInput.choose_rounds_to_win
      self.skill_level = GetUserInput.choose_skill_level(COMPUTER_SKILLS)
    end

    def to_h
      {
        x_color: x_color,
        o_color: o_color,
        human_color: human_color,
        computer_color: computer_color,
        start_color: start_color,
        skill_level: skill_level,
        rounds_to_win: rounds_to_win
      }
    end
  end

  class Match
    def initialize(args)
      @board = Board.new(args[:x_color], args[:o_color])
      @human = Human.new(board, args[:human_color])
      @computer = Computer.new(board, args[:computer_color], args[:skill_level])
      @schedule = Schedule.new(human, computer, player(args[:start_color]))
      @score_keeper = ScoreKeeper.new(args[:rounds_to_win])
    end

    def play
      loop do
        board.draw
        play_round
        break if score_keeper.match_winner
        reset_for_next_round
        GetUserInput.press_enter
      end
      MessageToUser.present_match_winner(score_keeper.match_winner)
    end

    private

    attr_reader :board, :human, :computer, :schedule, :score_keeper

    def player(color)
      { human.color => human, computer.color => computer }[color]
    end

    def play_round
      until board.terminal?
        schedule.active_player.choose_square
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
      current_scores = [score_keeper[human], score_keeper[computer]]

      if round_winner
        MessageToUser.present_round_winner(round_winner)
      else
        MessageToUser.announce_tie
      end

      MessageToUser.present_scores(*current_scores)
    end

    def reset_for_next_round
      board.reset
      schedule.reset
    end
  end

  class Game
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
      MessageToUser.welcome
    end

    def customize
      MessageToUser.display_settings(settings.to_h)
      return unless GetUserInput.customize?
      settings.customize
      MessageToUser.display_settings(settings.to_h)
      GetUserInput.press_enter
    end

    def play
      Match.new(settings.to_h).play
      play if GetUserInput.rematch?
    end

    def outro
      MessageToUser.goodbye
    end
  end
end

TTT::Game.new.start
