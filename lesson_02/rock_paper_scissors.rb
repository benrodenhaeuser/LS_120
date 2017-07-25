class Player
  def choose
    @move = Move.new
  end
end

class Move
  CHOICES = [:rock, :paper, :scissors]

  def initialize
    @choice = CHOICES.sample
  end
end

class Rule
  def initialize
    # not sure what the "state" of a rule object should be
  end
end

# not sure where "compare" goes yet
def compare(move1, move2)

end

class RPSGame
  attr_accessor :human, :computer

  def initialize
    @human = Player.new
    @computer = Player.new
  end

  def play
    display_welcome_message
    human.choose
    computer.choose
    display_winner
    display_goodbye_message
  end

  def display_welcome_message
    puts "hello!"
  end

  def display_goodbye_message
    puts "goodbye!"
  end

  def display_winner
    # todo
  end

end
