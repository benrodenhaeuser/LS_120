module Customizable
  AI = :smart # choose :smart (optimal play) or :dumb (random play)
  ROUNDS_TO_WIN = 2 # choose any integer
end

module Utils
  def clear
    system 'clear'
  end
end

module DrawBoard
  include Utils

  ROW_LENGTH = 3
  SQUARES = (1..ROW_LENGTH**2)
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  BLANK = ' '
  COL_DELIMITER = " | "
  NEW_LINE = "\n"
  ROW_DELIMITER = NEW_LINE + "-----------" + NEW_LINE

  def draw
    clear
    puts board_string
  end

  private

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

  private

  def payoff(player)
    if winner?(player)
      1
    elsif winner?(opponent_of(player))
      -1
    else
      0
    end
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
  include Negamax, DrawBoard

  WIN_LINES = [
    [1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
    [1, 4, 7], [2, 5, 8], [3, 6, 9], # cols
    [1, 5, 9], [3, 5, 7]             # diags
  ]

  attr_reader :human, :computer
  attr_accessor :moves, :winner, :active_player

  def initialize(human, computer)
    @moves = []
    @human = human
    @computer = computer
    @active_player = human
    @winner = nil
  end

  def <<(move)
    moves << move
  end

  def to_h
    @moves.map(&:to_a).to_h
  end

  def opponent_of(player)
    player == human ? computer : human
  end

  def available_squares
    SQUARES.select { |square| empty?(square) }
  end

  def full?
    available_squares.empty?
  end

  def winner?(player)
    WIN_LINES.any? { |line| line.all? { |square| to_h[square] == player } }
  end

  def terminal?
    players.any? { |player| winner?(player) } || full?
  end

  def switch_active_player
    self.active_player = opponent_of(active_player)
  end

  def reset
    initialize(human, computer)
  end

  private

  def empty?(square)
    to_h[square].nil?
  end

  def players
    [human, computer]
  end
end

module Prompt
  include Customizable

  # put into Utils starting here

  # todo: keyword argument for different types of prompts?
  INDENT = '    '
  PROMPT_SIGN = '--> '

  def prompt(message)
    puts PROMPT_SIGN + message
  end

  # put into Utils ending here

  # put into Game starting here

  def welcome
    prompt("Welcome to Tic Tac Toe!")
    prompt("Win #{ROUNDS_TO_WIN} rounds to win the match!")
  end

  def announce_invalid_input
    prompt("This is not a valid choice!")
  end

  def present_round_result
    board.winner ? present_winner : announce_tie
  end

  def present_winner
    case board.winner
    when computer then prompt("The computer wins this round.")
    when human    then prompt("You win this round.")
    end
  end

  def announce_tie
    prompt("This round is a tie.")
  end

  # todo: fix singular/plural
  def present_scores
    print INDENT
    puts "You have #{score_board[human]} points."
    print INDENT
    puts "Computer has #{score_board[computer]} points."
  end

  def present_match_winner
    case score_board.match_winner
    when computer then prompt("GAME OVER ~~~ The computer wins the match.")
    when human    then prompt("GAME OVER ~~~ You win the match.")
    end
  end

  def goodbye
    prompt("Thanks for playing Tic Tac Toe! Goodbye!")
  end

  # todo: next, we have three methods that request user input
  # common logic: a prompt and a gets wrapped in validation

  # todo: validation, list of available squares ("joinor")

  # the next one is the only method used by the player class.
  # all other methods here are used by the game class.

  def wait
    prompt("Press enter to continue.")
    print INDENT
    gets
  end

  # todo: validation
  def user_wants_to_play_again?
    prompt("Would you like to play again? (y/n)")
    print INDENT
    gets.chomp.start_with?('y')
  end

  # put into Game ending here

  # put into Human starting here
  def request_user_move
    prompt("Please choose your square.")
    print INDENT
    gets.chomp.to_i
  end
  # put into Human ending here

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

  private

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

class ScoreBoard
  include Customizable

  attr_accessor :match_winner, :scores

  def initialize(human, computer)
    @scores = { human => 0, computer => 0 }
    @match_winner = nil
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
  include Prompt, Utils

  attr_reader :human, :computer, :board, :score_board

  def start
    clear
    welcome
    wait
    play
    goodbye
  end

  private

  def play
    init
    loop do
      board.reset
      board.draw
      play_round
      break if score_board.match_winner
      wait
    end
    present_match_winner
    play if user_wants_to_play_again?
  end

  def init
    @human = Human.new
    @computer = Computer.new
    @board = Board.new(human, computer)
    @score_board = ScoreBoard.new(human, computer)
  end

  def play_round
    until board.terminal?
      board.active_player.choose(board)
      board.draw
      evaluate_position
      board.switch_active_player
    end
    present_round_result
    present_scores
  end

  def evaluate_position
    return unless board.winner?(board.active_player)
    winner = board.active_player
    board.winner = winner
    score_board[winner] += 1
    score_board.match_winner = winner if score_board.match_winner?(winner)
  end
end

Game.new.start
