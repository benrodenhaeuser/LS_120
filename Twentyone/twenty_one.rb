module TwentyOne
  module Utils
    def announce_invalid_input
      puts "Sorry, this is not a valid input."
    end
  end

  class Card
    attr_accessor :name, :suit, :raw_value

    def initialize(name, suit, raw_value)
      @name = name
      @raw_value = raw_value
      @suit = suit
    end

    def to_s
      name + " of " + suit + " "
    end

    def <=>(other_card) # todo: needed? yes if we want to sort it.
      0
    end

    # aces come first, then the faces, then 10 to 2 descending
    # within each category, spades precede clubs precede hearts precede diamonds

  end

  class Deck
    attr_reader :stock

    SUITS = ["\u2660".encode('utf-8'), "\u2663".encode('utf-8'), # spades, clubs
      "\u2665".encode('utf-8'), "\u2666".encode('utf-8')] # hearts, diamonds
    NUMBERS = (2..10)
    FACES = ['Jack', 'Queen', 'King']

    def initialize
      @stock = initial_card_stock.shuffle
    end

    def initial_card_stock
      cards = []
      SUITS.each do |suit|
        NUMBERS.each { |value| cards << Card.new(value.to_s, suit, value) }
        FACES.each { |face| cards << Card.new(face, suit, 10) }
        cards << Card.new('Ace', suit, 11)
      end
      cards
    end

    def deal_a_card(participant)
      participant << stock.pop
    end

    def to_s # todo: might not be needed in the end
      stock.map { |card| card.to_s }
    end

  end

  class Participant
    BUST_VALUE = 22

    attr_accessor :hand

    def initialize
      @hand = []
    end

    def <<(card)
      hand << card
    end

    def hit(deck)
      deck.deal_a_card(self)
    end

    def busted?
      value >= BUST_VALUE
    end

    def value
      value = hand.map { |card| card.raw_value }.inject(&:+)
      number_of_aces.times { value -= 10 if value > BUST_VALUE }
      value
    end

    def number_of_aces
      hand.select { |card| card.name == 'ace' }.count
    end

    def display_hand
      hand.map { |card| card.to_s } # todo
    end
  end

  class Player < Participant
    include Utils

    def take_turn(deck)
      loop do
        break if busted?
        ask_to_hit_or_stay
        answer = gets.chomp
        next announce_invalid_input unless answer.downcase.start_with?('s', 'h')
        break if answer.downcase.start_with?('s')
        hit(deck) if answer.downcase.start_with?('h')
      end
    end

    def ask_to_hit_or_stay
      puts "Hit or stay? (h/s)"
    end

    def to_s
      "Player"
    end
  end

  class Dealer < Participant
    DEALER_STAY_VALUE = 17

    def take_turn(deck)
      hit(deck) until stay? || busted?
    end

    def stay?
      value >= DEALER_STAY_VALUE
    end

    def to_s
      "Dealer"
    end

    def display_first
      [hand.first.to_s] # todo
    end
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

  class Game
    attr_accessor :deck, :player, :dealer, :score_keeper

    def initialize
      @deck = Deck.new
      @player = Player.new
      @dealer = Dealer.new
      @score_keeper = ScoreKeeper.new(2)
    end

    def play_round
      deal_two_cards_each
      show_initial_cards
      participants_take_turns
      evaluate_round
      present_hands
      present_winner
    end

    def deal_two_cards_each
      [player, dealer].each { |guy| 2.times { deck.deal_a_card(guy) } }
    end

    def show_initial_cards # todo
      puts "#{player}: #{player.display_hand} // value: #{player.value}"
      puts "#{dealer}: #{dealer.display_first} // value: #{dealer.value}"
    end

    def participants_take_turns
      [player, dealer].each do |guy|
        guy.take_turn(deck)
        break score_keeper.keep_score(other_guy(guy)) if guy.busted?
      end
    end

    def other_guy(guy)
      guy == player ? dealer : player
    end

    def evaluate_round
      return if score_keeper.round_winner || player.value == dealer.value
      round_winner = [player, dealer].max_by { |guy| guy.value }
      score_keeper.keep_score(round_winner)
    end

    def present_hands
      puts "#{player}: #{player.value}, hand: #{player.display_hand}"
      puts "#{dealer}: #{dealer.value}, hand: #{dealer.display_hand}"
    end

    def present_winner # todo
      if score_keeper.round_winner
        puts "#{score_keeper.round_winner} wins."
      else
        puts "It's a tie."
      end
    end
  end
end

TwentyOne::Game.new.play_round

# problem: I would like to present *both* hands after every individual
# hit action of player. but the player only knows her own hand.
# this seems to suggest that we cannot do the player turn fully inside of
# player.
