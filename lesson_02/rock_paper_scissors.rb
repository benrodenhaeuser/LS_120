class Move
  VALUES = ['rock', 'paper', 'scissors']

  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def rock?
    @value == 'rock'
  end

  def scissors?
    @value == 'scissors'
  end

  def paper?
    @value == 'paper'
  end

  def >(other_move)
    (rock? && other_move.scissors?) ||
      (paper? && other_move.rock?) ||
      (scissors? && other_move.paper?)
  end

  def <(other_move)
    other_move > self
  end

  def to_s
    value
  end
end

class Player
  attr_accessor :move

  def initialize
    @move = nil
  end
end

class Human < Player
  def choose
    choice = nil
    loop do
      puts "please make your choice among rock, paper, scissors"
      choice = gets.chomp
      break if Move::VALUES.include?(choice)
      puts "invalid choice"
    end
    self.move = Move.new(choice)
  end
end

class Computer < Player
  def choose
    self.move = Move.new(Move::VALUES.sample)
  end
end

class RPSGame
  attr_accessor :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def play
    display_welcome_message
    loop do
      human.choose
      computer.choose
      display_moves
      display_winner
      break unless play_again?
    end
    display_goodbye_message
  end

  def play_again?
    answer = nil
    loop do
      puts "do you want to play again?"
      answer = gets.chomp
      break if answer.downcase.start_with?('y', 'n')
      puts "invalid choice"
    end

    answer.start_with?('y')
  end

  def display_welcome_message
    puts "welcome to rock, paper, scissors!"
  end

  def display_goodbye_message
    puts "thanks for playing rock, paper, scissors! goodbye!"
  end

  def display_moves
    puts "you chose #{human.move}"
    puts "computer chose #{computer.move}"
  end

  def display_winner
    result =
      if human.move > computer.move
        "you won"
      elsif human.move < computer.move
        "the computer won"
      else
        "it's a tie."
      end
    puts result
  end
end

RPSGame.new.play
