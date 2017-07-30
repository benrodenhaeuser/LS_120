module Customizable
  AI = :smart # choose either :smart or :dumb
  ROUNDS_TO_WIN = 2 # choose any integer
end

module Prompt
  include Customizable

  INDENT = '    '

  def prompt(message)
    puts "--> #{message}"
  end

  def welcome_the_user
    prompt("Welcome to Tic Tac Toe!")
    prompt("Win #{ROUNDS_TO_WIN} rounds to win the match!")
  end

  def announce_invalid_input
    prompt("This is not a valid choice!")
  end

  def present_winner
    case winner
    when computer then prompt("Winner ~~~ The computer wins this round.")
    when human    then prompt("Winner ~~~ You win this round.")
    end
  end

  def announce_tie
    prompt("This round is a tie.")
  end

  def present_scores
    print INDENT
    puts "Scores ~~~ You #{scores[human]} : #{scores[computer]} Computer"
  end

  def present_match_winner
    case match_winner
    when computer then prompt("GAME OVER ~~~ The computer wins the match.")
    when human    then prompt("GAME OVER ~~~ You win the match.")
    end
  end

  def say_goodbye
    prompt("Thanks for playing Tic Tac Toe! Goodbye!")
  end

  # todo refactor with validation and list of available squares
  def request_user_move
    prompt("Please choose your square.")
    print INDENT
    gets.chomp.to_i
  end

  def wait_for_user
    prompt("Press enter to continue.")
    print INDENT
    gets
  end

  # todo refactor with validation
  def user_wants_to_play_again?
    prompt("Would you like to play again? (y/n)")
    print INDENT
    gets.chomp.start_with?('y')
  end
end

module DisplayBoard
  ROW_LENGTH = 3
  SQUARES = (1..ROW_LENGTH**2)
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  BLANK = ' '
  COL_DELIMITER = " | "
  NEW_LINE = "\n"
  ROW_DELIMITER = NEW_LINE + "-----------" + NEW_LINE

  def display_board
    system 'clear'
    puts board_string
  end

  def board_string
    rows = markers.each_slice(ROW_LENGTH).map do |row|
      BLANK + row.join(COL_DELIMITER) + BLANK
    end
    NEW_LINE + rows.join(ROW_DELIMITER) + NEW_LINE * 2
  end

  def markers
    SQUARES.map { |square| marker(square) }
  end

  def marker(square)
    case to_h[square]
    when human    then HUMAN_MARKER
    when computer then COMPUTER_MARKER
    else
      BLANK
    end
  end
end

module Negamax
  PAYOFF_WIN = 1
  PAYOFF_LOSS = -1
  PAYOFF_TIE = 0

  def payoff(player)
    if winner?(player)
      PAYOFF_WIN
    elsif winner?(opponent_of(player))
      PAYOFF_LOSS
    else
      PAYOFF_TIE
    end
  end

  def negamax(player, top = false, memo = {})
    unless memo[to_h]
      if terminal?
        memo[to_h] = payoff(player)
      else
        best_option = select_best(scored_options(player, memo))
        top ? (return best_option.first) : memo[to_h] = best_option.last
      end
    end
    memo[to_h]
  end

  def scored_options(player, memo)
    available_squares.map do |square|
      moves << Move.new(square, player)
      value_for_square = -negamax(opponent_of(player), false, memo)
      moves.pop
      [square, value_for_square]
    end
  end

  def select_best(options)
    options.max_by { |_, value_for_square| value_for_square }
  end
end

class Board
  include Negamax, DisplayBoard

  WIN_LINES = [
    [1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
    [1, 4, 7], [2, 5, 8], [3, 6, 9], # cols
    [1, 5, 9], [3, 5, 7]             # diags
  ]

  attr_reader :human, :computer
  attr_accessor :moves

  def initialize(human, computer)
    @moves = []
    @human = human
    @computer = computer
  end

  def available_squares
    (1..9).to_a.select { |square| empty?(square) }
  end

  def empty?(square)
    to_h[square].nil?
  end

  def full?
    available_squares.empty?
  end

  def <<(move)
    moves << move
  end

  def opponent_of(player)
    player == human ? computer : human
  end

  def winner?(player)
    WIN_LINES.any? { |line| line.all? { |square| to_h[square] == player } }
  end

  def players
    [human, computer]
  end

  def terminal?
    players.any? { |player| winner?(player) } || full?
  end

  def to_h
    @moves.map(&:to_a).to_h
  end
end

class Player; end

class Human < Player
  include Prompt

  def choose(board)
    square = nil
    loop do
      square = request_user_move
      break if board.available_squares.include?(square)
      announce_invalid_input
    end
    board << Move.new(square, self)
  end
end

class Computer < Player
  include Customizable

  def choose(board)
    AI == :dumb ? choose_randomly(board) : choose_optimally(board)
  end

  def choose_randomly(board)
    board << Move.new(board.available_squares.sample, self)
  end

  def choose_optimally(board)
    board << Move.new(board.negamax(self, :top), self)
  end
end

class Move
  attr_reader :square, :player

  def initialize(square, player)
    @square = square
    @player = player
  end

  def to_a
    [square, player]
  end
end

class Game
  include Customizable, Prompt

  attr_reader :human, :computer, :board
  attr_accessor :active_player, :winner, :scores, :match_winner

  def initialize
    @human = Human.new
    @computer = Computer.new
    @board = Board.new(human, computer)
    @active_player = human
    @winner = nil
    @scores = { human => 0, computer => 0 }
    @match_winner = nil
  end

  def start
    system 'clear'
    welcome_the_user
    wait_for_user
    play
    say_goodbye
  end

  def play
    board.display_board
    loop do
      round_reset
      play_round
      break present_match_winner if match_winner
      wait_for_user
    end
    initialize
    play if user_wants_to_play_again?
  end

  def play_round
    loop do
      active_player.choose(board)
      board.display_board
      evaluate_game_state
      break present_winner if winner
      break announce_tie if board.full?
      switch_active_player
    end
    present_scores
  end

  def evaluate_game_state
    if board.winner?(active_player)
      self.winner = active_player
      scores[winner] += 1
    end
    self.match_winner = winner if scores[winner] == ROUNDS_TO_WIN
  end

  def switch_active_player
    self.active_player = board.opponent_of(active_player)
  end

  def round_reset
    self.winner = nil
    self.active_player = human
    board.moves = []
    board.display_board
  end
end

Game.new.start
