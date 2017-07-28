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
  attr_accessor :move, :score

  def initialize
    @move = nil
    @score = 0
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
  ROUNDS_TO_WIN = 2

  attr_accessor :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def play
    display_welcome_message
    loop do
      reset_scores
      play_one_match
      break unless play_another_match?
    end
    display_goodbye_message
  end

  def reset_scores
    computer.score = 0
    human.score = 0
  end

  def play_one_match
    loop do
      human.choose
      computer.choose
      display_moves
      display_round_result
      break display_overall_winner if overall_winner?
    end
  end

  def play_another_match?
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

  def display_round_result
    round_result =
      if human.move > computer.move
        human.score += 1
        "you won this round"
      elsif human.move < computer.move
        computer.score += 1
        "the computer won this round"
      else
        "this round is a tie."
      end
    puts round_result
    puts "current computer score: #{computer.score}"
    puts "your current score: #{human.score}"
  end

  def display_overall_winner
    if human.score >= ROUNDS_TO_WIN
      puts "human won overall game"
    elsif computer.score >= ROUNDS_TO_WIN
      puts "computer won overall game"
    end
  end

  def overall_winner?
    human.score >= ROUNDS_TO_WIN || computer.score >= ROUNDS_TO_WIN
  end

end

RPSGame.new.play
