
module Screen
  WIDTH = 51

  def clear_screen
    system('clear') || system('cls')
  end

  def prompt(msg)
    puts "=> #{msg}"
  end

  at_exit { puts '=> Thanks for playing. Goodbye!' }
end

module Printable
  COMMANDS = %w(h b q help board quit).freeze
  COMMAND_DESCRIPTIONS = {
    help: 'Show this guide',
    board: 'Show current board',
    quit: 'Quit the game'
  }.freeze

  include Screen

  def bordered_print(border_type)
    puts border_type * WIDTH
    puts yield
    puts border_type * WIDTH
  end

  def print_help(board)
    bordered_print_with_title('  The first to 5 wins  ', '—') do
      board.draw(WIDTH, (0..9).to_a)
      list_commands
    end
  end

  def bordered_print_with_title(title, border_type)
    puts title.center(WIDTH, border_type)
    puts yield
    puts "\n" + (border_type * WIDTH)
  end

  def list_commands
    COMMAND_DESCRIPTIONS.map do |command, action|
      "    [#{command[0]}] #{command}" +
        "#{action}    ".rjust(WIDTH - (command.size + 8))
    end
  end

  def print_score_and_board(board, human, bot)
    clear_screen
    print_score(human, bot)
    board.draw(WIDTH)
    puts '—' * WIDTH
  end

  def print_score(human, bot)
    bordered_print('—') { combine_score_sides(human, bot) }
  end

  def combine_score_sides(human, bot)
    left = construct_score_sides(human, :left)
    right = construct_score_sides(bot, :right)
    "#{left} : #{right}"
  end

  def construct_score_sides(player, side)
    case side
    when :left  then construct_left_score(player)
    when :right then construct_right_score(player)
    end
  end

  def construct_left_score(player)
    text = "[#{player.marker}] #{player.name}"
    justification = calc_justification(text.size)
    text + justify_score(player.score.to_s, justification)
  end

  def construct_right_score(player)
    text = "#{player.name} [#{player.marker}]"
    justification = calc_justification(player.score.to_s.size)
    player.score.to_s + justify_score(text, justification)
  end

  def calc_justification(text)
    half_width = (WIDTH - 3) / 2
    half_width - text
  end

  def justify_score(element, justification)
    element.rjust(justification)
  end

  def joinor(arr, delimiter = ', ', word = 'or')
    arr[-1] = "#{word} #{arr.last}" if arr.size > 1
    arr.size == 2 ? arr.join(' ') : arr.join(delimiter)
  end
end

module InputValidator
  include Printable

  def keep_input?(board, element)
    first = true
    loop do
      input = request_confirmation(first, element)
      first = false
      answer = validate_input(input, board)
      next if answer.nil?
      break answer ? true : false
    end
  end

  def request_confirmation(first, element)
    prompt "That's a command." if first
    prompt "Do you still want to use that #{element}? (y/n)"
    gets.chomp.downcase
  end

  def validate_input(input, board)
    case input
    when 'y', 'yes' then true
    when 'n', 'no'  then false
    when *COMMANDS  then delegate_commands(input, board)
    else                 prompt 'Unrecognized input.'
    end
  end

  def delegate_commands(input, board)
    case input
    when 'q', 'quit'  then TicTacToe.quit
    when 'h', 'help'  then print_help(board)
    when 'b', 'board' then prompt "There's no board to show."
    end
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |num| squares[num] = Square.new }
  end

  def []=(num, marker)
    squares[num].marker = marker
  end

  def draw(width, squares = @squares)
    rjust = ' ' * ((width - 23) / 2)
    squares_arr = squares.is_a?(Hash) ? squares.keys : squares
    add_board_spacing { build_board(rjust, squares_arr, squares) }
  end

  def add_board_spacing
    puts "\n\n"
    yield
    puts "\n\n"
  end

  def build_board(rjust, squares_arr, squares)
    squares_arr.each do |num|
      next unless num % 3 == 0
      squares_in_row = [squares[num - 2], squares[num - 1], squares[num]]
      puts fill_row(rjust, squares_in_row) if num > 0
      puts "#{rjust}———————│———————│———————" if (num / 3).between?(1, 2)
    end
  end

  def fill_row(rjust, squares)
    vert_lines = "       │       │"
    row = "   #{squares.first}   │   #{squares[1]}   │   #{squares.last}"
    "#{rjust}#{vert_lines}\n#{rjust}#{row}\n#{rjust}#{vert_lines}"
  end

  def unmarked_squares
    squares.keys.select { |num| squares[num].unmarked? }
  end

  def full?
    unmarked_squares.empty?
  end

  def winning_marker
    WINNING_LINES.each do |line|
      square_values = squares.values_at(*line)
      return square_values.first.marker if full_line?(square_values)
    end
    nil
  end

  def select_markers(line)
    squares.values_at(*line).map(&:marker)
  end

  private

  attr_reader :squares

  def full_line?(square_values)
    markers = square_values.reject(&:unmarked?).map(&:marker)
    (markers.min == markers.max) && (markers.size == 3) ? true : false
  end
end

class Square
  EMPTY_MARKER = ' '.freeze

  attr_accessor :marker

  def initialize(marker = EMPTY_MARKER)
    @marker = marker
  end

  def to_s
    marker
  end

  def unmarked?
    marker == EMPTY_MARKER
  end
end

class Player
  include InputValidator

  attr_accessor :name, :marker, :score

  def initialize
    @score = 0
  end
end

class Human < Player
  def choose_name(board)
    first = true
    loop do
      input = request_name(first)
      first = false
      break input if valid_name?(input.downcase, board)
    end
  end

  def choose_marker(board, markers)
    first = true
    loop do
      input = request_marker(first)
      first = false
      break input.upcase if valid_marker?(input.downcase, board, markers)
    end
  end

  def choose_square(board, human, bot)
    loop do
      prompt "Choose square #{joinor(board.unmarked_squares)}:"
      input = gets.chomp
      break input.to_i if valid_square?(input.downcase, board, human, bot)
    end
  end

  private

  def request_name(first)
    prompt 'Hello!' if first
    prompt "What's your name?"
    gets.chomp
  end

  def request_marker(first)
    prompt "Welcome, #{name}!" if first
    prompt 'Choose a marker between A and Z:'
    gets.chomp
  end

  def valid_name?(input, board)
    limit = (WIDTH - 19) / 2
    if input =~ /^[A-Z]{1,#{limit}}$/i
      COMMANDS.include?(input) ? keep_input?(board, 'name') : true
    else
      prompt "Sorry, that name isn't allowed."
    end
  end

  def valid_marker?(input, board, markers)
    error = "Sorry, that marker isn't available."
    case input
    when *COMMANDS[0..2]             then keep_input?(board, 'marker')
    when *COMMANDS[3..COMMANDS.size] then delegate_commands(input, board)
    when *markers.map(&:downcase)    then true
    else                                  prompt error
    end
  end

  def valid_square?(input, board, human, bot)
    unmarked_squares = board.unmarked_squares.map(&:to_s)
    error = "Sorry, that square isn't available."
    case input
    when 'n', 'q', 'no', 'quit' then TicTacToe.quit
    when 'h', 'help'            then print_help(board)
    when 'b', 'board'           then print_score_and_board(board, human, bot)
    when *unmarked_squares      then true
    else                             prompt error
    end
  end
end

class Bot < Player
  def assign_name
    %w(BB-8 WALL-E Bumblebee Chappie).sample
  end

  def assign_move(board, human_marker)
    square = strategy(board, marker)
    square ||= strategy(board, human_marker)
    square ||= 5 if board.unmarked_squares.include?(5)
    square ||= board.unmarked_squares.sample
    square
  end

  def strategy(board, marker)
    Board::WINNING_LINES.each do |line|
      square = find_square(board, line, marker)
      return square if square
    end
    nil
  end

  def find_square(board, line, marker)
    markers = board.select_markers(line)
    open_square = markers.index(Square::EMPTY_MARKER)
    return line[open_square] if [marker, marker] == markers - [' ']
  end
end

class TicTacToe
  include Printable

  attr_accessor :board, :human, :bot

  def initialize
    @board = Board.new
    @human = Human.new
    @bot = Bot.new
    @markers = ('A'..'Z').to_a
    play
  end

  def self.quit
    exit
  end

  private

  attr_reader :markers

  def play
    intro
    request_human_info
    assign_bot_info
    Game.new(board, human, bot)
    TicTacToe.quit
  end

  def intro
    clear_screen
    banner
    print_help(board)
  end

  def banner
    bordered_print('=') { 'Tic Tac Toe'.center(WIDTH) }
  end

  def request_human_info
    human.name = human.choose_name(board)
    human.marker = markers.delete(human.choose_marker(board, markers))
  end

  def assign_bot_info
    bot.name = bot.assign_name
    bot.marker = markers.delete(markers.sample)
  end
end

class Game
  include InputValidator

  MAX_SCORE = 5

  attr_accessor :board, :human, :bot, :current_marker

  def initialize(board, human, bot)
    @board = board
    @human = human
    @bot = bot
    play
  end

  private

  def play
    loop do
      assign_current_marker
      Round.new(board, human, bot, current_marker)
      next board.reset unless MAX_SCORE <= [human.score, bot.score].max
      play if play_again?
    end
  end

  def assign_current_marker
    human_moves_first = first_to_move?(board, [human.score, bot.score])
    self.current_marker = human_moves_first ? human.marker : bot.marker
  end

  def first_to_move?(board, scores)
    first = true
    loop do
      input = request_first_move_pref(first, scores)
      first = false
      answer = validate_input(input, board)
      next if answer.nil?
      break answer ? true : false
    end
  end

  def request_first_move_pref(first, scores)
    conditional_prompt(scores) if first
    prompt 'Would you like to go first? (y/n)'
    gets.chomp.downcase
  end

  def conditional_prompt(scores)
    if scores.max < 1
      prompt 'Great!'
    else
      prompt 'Setting up the next round...'
      sleep(1.25)
      prompt 'Ready!'
      sleep(0.25)
    end
  end

  def play_again?
    reset
    loop do
      prompt 'Do you want to play again? (y/n)'
      input = gets.chomp.downcase
      break true if delegate_input(input)
    end
  end

  def reset
    board.reset
    human.score = bot.score = 0
  end

  def delegate_input(input)
    case input
    when 'y', 'yes'             then true
    when 'n', 'q', 'no', 'quit' then TicTacToe.quit
    when 'h', 'help'            then print_help(board)
    when 'b', 'board'           then prompt "There's no board to show."
    else                             prompt 'Unrecognized input.'
    end
  end
end

class Round
  include Printable

  attr_accessor :board, :human, :bot, :current_marker

  def initialize(board, human, bot, current_marker)
    @board = board
    @human = human
    @bot = bot
    @current_marker = current_marker
    play
  end

  private

  def play
    alternate_turn
    update_score
    print_outcome
  end

  def alternate_turn
    loop do
      print_score_and_board(board, human, bot)
      player_move
      self.current_marker = alternate_marker
      break if board.winning_marker || board.full?
    end
  end

  def player_move
    case current_marker
    when human.marker then board[human_choose_square] = human.marker
    when bot.marker   then board[bot_choose_square] = bot.marker
    end
  end

  def human_choose_square
    human.choose_square(board, human, bot)
  end

  def bot_choose_square
    bot.assign_move(board, human.marker)
  end

  def alternate_marker
    current_marker == human.marker ? bot.marker : human.marker
  end

  def update_score
    case board.winning_marker
    when human.marker then human.score += 1
    when bot.marker   then bot.score += 1
    end
  end

  def print_outcome
    print_score_and_board(board, human, bot)
    prompt case board.winning_marker
           when human.marker then 'You won!'
           when bot.marker   then "#{bot.name} won!"
           else                   "It's a tie!"
           end
  end
end

TicTacToe.new
