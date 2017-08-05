module Customizable
  AI = :smart # choose :smart (optimal play) or :dumb (random play)
  ROUNDS_TO_WIN = 2 # choose any integer
end

module Utils
  def clear
    system 'clear'
  end

  INDENT = '    '
  PROMPT_SIGN = '--> '
end

module Message
  # this is actually just one big method, kind of. This could be clarified by making all of this stuff calls to the prompt method, with the help of a MESSAGES hash.

  # Message.prompt('invalid_input')
  # then the prompt method would use a hash to retrieve the actual message.
  # we could also make substitutions, and format the prompt.
  # like we did in procedural TTT.

  include Utils, Customizable

  # todo: keyword argument for different types of prompts?
  def self.prompt(message)
    puts PROMPT_SIGN + message
  end

  def self.welcome
    prompt("Welcome to Tic Tac Toe!")
    prompt("Win #{ROUNDS_TO_WIN} rounds to win the match!")
  end

  def self.announce_invalid_input
    prompt("This is not a valid choice!")
  end

  def self.present_winner(winner)
    winner ? prompt("The winner is #{winner}.") : prompt("This round is a tie.")
  end

  # todo: fix singular/plural
  # todo: Utils should provide smarter way to do this
  def self.present_scores(human_score, computer_score)
    print INDENT
    puts "You have #{human_score} points."
    print INDENT
    puts "Computer has #{computer_score} points."
  end

  def self.present_match_winner(match_winner)
    prompt("GAME OVER ~~~ The match winner is #{match_winner}.")
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

  def self.please_choose
    prompt("Please choose your square.")
  end
end

module Request
  include Utils

  def self.hit_enter
    Message.press_enter
    print INDENT
    gets
  end

  # todo: validation
  # todo: provide better way to do this in Utils
  def self.play_again?
    Message.want_to_play_again
    print INDENT
    gets.chomp.start_with?('y')
  end

  # todo: Utils should provide smarter way to do this
  def self.choose_move
    Message.please_choose
    print INDENT
    gets.chomp.to_i
  end
end

# -------
# DrawBoard and NegaMax
# -------

# todo: the next two modules are not really modules. they are actually part of the Board class. we have only separated them to make the main class shorter.

# todo: correct use of a module? should it be a namespacing module?

# we might want to call it like this:
# Draw.board
# Draw.score_board
# *But* then we would need to pass in the board/score_board as well
# Draw.board(board)
# Draw.score_board(score_board)
# So this is not a good solution.
# A board has a BoardDrawer.

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
    case to_h[square] # here, we need the board.
    when human    then HUMAN_MARKER
    when computer then COMPUTER_MARKER
    else
      BLANK
    end
  end
end

# todo: correct use of a module?
module NegaMax
  def nega_max(player, top = false, memo = {})
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

  # here, we also need a player and its opponent.

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
      value_for_square = -nega_max(opponent_of(player), false, memo)
      moves.pop
      [square, value_for_square]
    end
  end

  def select_best(options)
    options.max_by { |_, value_for_square| value_for_square }
  end
end

class Board
  include NegaMax, DrawBoard

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

  def evaluate
    self.winner = active_player if winner?(active_player)
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

class Player; end

class Human < Player
  include Utils

  def choose(board)
    square = nil
    loop do
      square = Request.choose_move
      break if board.available_squares.include?(square)
      Message.announce_invalid_input
    end
    board << Move.new(square, self)
  end
end

# this class is all about the board: it needs to have the board as a collaborator.
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
    board << Move.new(board.nega_max(self, :top), self)
  end

  # would also be nice to do negamax here. then, we would need a board, and two players. We could have the opponent as an instance variable of computer. Then, we could do negamax within Computer, potentially.

  # we could also have, in the game class, an instance variable opponents. But then, we would need to pass the board and the opponents. but this is getting sort of complicated, right?
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

  attr_accessor :scores, :match_winner

  def initialize
    @scores = Hash.new { |hash, key| hash[key] = 0 }
    @match_winner = nil
  end

  def evaluate(winner)
    scores[winner] += 1
    self.match_winner = winner if match_winner?(winner)
  end

  def [](player)
    scores[player]
  end

  private

  def []=(player, value)
    scores[player] = value
  end

  def match_winner?(player)
    scores[player] == ROUNDS_TO_WIN
  end
end

class Game
  include Utils

  def start
    clear
    Message.welcome
    Request.hit_enter
    play
    Message.goodbye
  end

  private

  attr_reader :human, :computer, :board, :score_board

  def play
    init_match
    loop do
      board.reset
      board.draw
      play_round
      break if score_board.match_winner
      Request.hit_enter
    end
    Message.present_match_winner(score_board.match_winner)
    play if Request.play_again?
  end

  def init_match
    @human = Human.new
    @computer = Computer.new
    @board = Board.new(human, computer)
    @score_board = ScoreBoard.new
  end

  def play_round
    until board.terminal?
      board.active_player.choose(board) # not nice
      board.draw
      board.evaluate
      board.switch_active_player
    end
    score_board.evaluate(board.winner)
    Message.present_winner(board.winner)
    Message.present_scores(score_board[human], score_board[computer])
    # ^ debatable
  end

end

Game.new.start
