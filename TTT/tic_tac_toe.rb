module Prompt
  INDENT = '    '

  def prompt(message)
    puts "--> #{message}"
  end

  def request_user_input
    prompt("Please make your choice.")
    print INDENT
    gets.chomp.to_i
  end

  def wait_for_user
    prompt("Press enter to begin the game.")
    print INDENT
    gets
  end

  def announce_invalid_input
    prompt("This is not a valid choice!")
  end

  def announce_winner
    case winner
    when computer then prompt("The computer wins this round.")
    when human then prompt("You win this round.")
    end
  end

  def announce_tie
    prompt("This round is a tie.")
  end

  def welcome_the_user
    prompt("Welcome to Tic Tac Toe!")
  end

  def say_goodbye
    prompt("Thanks for playing Tic Tac Toe! Goodbye!")
  end
end

module Display
  ROW_LENGTH = 3
  SQUARES = (1..ROW_LENGTH**2)
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  BLANK = ' '
  COL_DELIMITER = " | "
  NEW_LINE = "\n"
  ROW_DELIMITER = NEW_LINE + "-----------" + NEW_LINE

  def display_position
    system 'clear'
    puts board_string
  end

  def board_string
    markers = SQUARES.map { |square| marker(square) }

    rows = markers.each_slice(ROW_LENGTH).map do |row|
      BLANK + row.join(COL_DELIMITER) + BLANK
    end

    NEW_LINE + rows.join(ROW_DELIMITER) + NEW_LINE * 2
  end

  def marker(square)
    case board.to_h[square]
    when human then HUMAN_MARKER
    when computer then COMPUTER_MARKER
    else
      BLANK
    end
  end
end

class Player; end

class Human < Player
  include Prompt

  def choose(board)
    square = nil
    loop do
      square = request_user_input
      break if board.available_squares.include?(square)
      announce_invalid_input
    end
    board << Move.new(square, self)
  end
end

class Computer < Player
  INTELLIGENCE = :dumb # configurable: :smart or :dumb

  def choose(board)
    INTELLIGENCE == :dumb ? choose_randomly(board) : choose_optimally(board)
  end

  def choose_randomly(board)
    board << Move.new(board.available_squares.sample, self)
  end

  def choose_optimally(board)
    nil # todo
  end

  # this algorithm needs information about the players, including "opponent_of".
  def nega_max(player, state, top = false)
    if terminal?(state)
      best_value = payoff(player, state)
    else
      best = available_moves(state).map do |move|
        make(move, player, state)
        value_for_move = -(nega_max(opponent(player), state))
        unmake(move, state)
        [move, value_for_move]
      end.max_by { |move, value_for_move| value_for_move }
      top ? (return best.first) : best_value = best.last
    end
    best_value
  end

end

class Board
  WIN_LINES = [
    [1, 2, 3], [4, 5, 6], [7, 8, 9], # rows
    [1, 4, 7], [2, 5, 8], [3, 6, 9], # cols
    [1, 5, 9], [3, 5, 7]             # diags
  ]

  attr_reader :moves

  def initialize
    @moves = []
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

  def winner?(player)
    WIN_LINES.any? { |line| line.all? { |square| to_h[square] == player } }
  end

  def to_h
    @moves.map(&:to_a).to_h
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

class TTTGame
  include Prompt, Display

  attr_reader :human, :computer, :board
  attr_accessor :active_player, :winner

  def initialize
    @human = Human.new
    @computer = Computer.new
    @board = Board.new
    @active_player = @human
    @winner = nil
  end

  def play
    welcome_the_user
    wait_for_user
    display_position
    # todo: play a certain number of rounds
    play_round

    say_goodbye
  end

  def play_round
    loop do
      active_player.choose(board)
      display_position
      evaluate_winner
      break announce_winner if winner
      break announce_tie if board.full?
      switch_active_player
    end
  end

  def evaluate_winner
    self.winner = active_player if board.winner?(active_player)
  end

  def switch_active_player
    self.active_player = opponent_of(active_player)
  end

  def opponent_of(player)
    player == human ? computer : human
  end
end

TTTGame.new.play
