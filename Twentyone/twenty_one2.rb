module TwentyOne
  module Utils
    def clear_terminal
      system 'clear'
    end

    def announce_invalid_input
      puts "Sorry, this is not a valid input."
    end

    def please_press_enter
      puts "Press enter to continue."
      gets
    end
  end

  class Card
    attr_accessor :name, :suit, :raw_value

    def initialize(name, suit, raw_value)
      @name = name
      @raw_value = raw_value
      @suit = suit
    end

    # todo: refactor
    def display
      ("-" * 9) + "\n" +
      "|" + (" " * 7) + "|" +  "\n" +
      "|" + name.center(7) + "|" + "\n" +
      "|" + suit.center(7) + "|" + "\n" +
      "|" + (" " * 7) + "|" + "\n" +
      ("-" * 9) + "\n"
    end
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

    def reset
      initialize
    end
  end

  class Participant
    include Utils

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
      number_of_aces.times { value -= 10 if value >= BUST_VALUE }
      value
    end

    def number_of_aces
      hand.select { |card| card.name == 'ace' }.count
    end

    def display
      hand
        .map { |card| card.display.split("\n") }
        .transpose
        .map { |line| line.join(' ') }
        .join("\n")
    end

    def reset
      initialize
    end
  end

  class Player < Participant
    def to_s
      "Player"
    end
  end

  class Dealer < Participant
    DEALER_STAY_VALUE = 17

    def stay?
      value >= DEALER_STAY_VALUE
    end

    def to_s
      "Dealer"
    end

    def display_first
      hand.first.display
    end

    def value_of_first
      hand.first.raw_value
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

    def update_with_winner(round_winner)
      self.round_winner = round_winner
      scores[round_winner] += 1
      self.match_winner = round_winner if match_winner?(round_winner)
    end

    def [](player)
      scores[player]
    end

    def reset
      initialize(rounds_to_win)
    end

    def round_reset
      round_winner = nil
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
    include Utils

    ROUNDS_TO_WIN = 2

    attr_accessor :deck, :player, :dealer, :score_keeper

    def initialize
      @deck = Deck.new
      @player = Player.new
      @dealer = Dealer.new
      @score_keeper = ScoreKeeper.new(ROUNDS_TO_WIN)
    end

    def start
      welcome
      play
      good_bye
    end

    def play
      reset_for_current_match
      play_match
      present_match_winner
      return unless play_some_more?
      play
    end

    def play_match
      reset_for_current_round
      deal_two_cards_each
      player_takes_turn
      dealer_takes_turn
      evaluate_round
      present_results
      return if score_keeper.match_winner
      please_press_enter
      play_match
    end

    def play_some_more?
      answer = nil
      loop do
        puts "Would you like to play some more? (y/n)"
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        announce_invalid_input
      end
      answer.start_with?('y')
    end

    def deal_two_cards_each
      [player, dealer].each { |guy| 2.times { deck.deal_a_card(guy) } }
      show_hands
    end

    def player_takes_turn
      loop do
        break if player.busted?
        puts "Hit or stay? (h/s)"
        answer = gets.chomp
        break if answer.downcase.start_with?('s')
        next announce_invalid_input unless answer.downcase.start_with?('h')
        player.hit(deck)
        show_hands
      end
    end

    def dealer_takes_turn
      return if player.busted?
      dealer.hit(deck) until dealer.stay?
    end

    def evaluate_round
      return if player.value == dealer.value
      round_winner =
        if player.busted?
          dealer
        elsif dealer.busted?
          player
        else
          [player, dealer].max_by { |guy| guy.value }
        end
      score_keeper.update_with_winner(round_winner)
    end

    def present_results
      show_hands(:full)
      present_winner
    end

    def show_hands(full = false)
      clear_terminal
      puts ""
      puts "Player (#{score_keeper[player]} of #{ROUNDS_TO_WIN}):"
      puts player.display
      puts ""
      puts "Dealer (#{score_keeper[dealer]} of #{ROUNDS_TO_WIN}):"
      puts (full ? dealer.display : dealer.display_first)
      puts ""
      puts "Player's total is #{player.value}."
      puts (full ? "Dealer has #{dealer.value}." : "Dealer's first is worth #{dealer.value_of_first}." )
    end

    def present_winner
      if score_keeper.round_winner
        puts "#{score_keeper.round_winner} wins!"
      else
        puts "It's a tie."
      end
    end

    def reset_for_current_round
      deck.reset
      player.reset
      dealer.reset
      score_keeper.round_reset
    end

    def reset_for_current_match
      score_keeper.reset
    end

    def welcome
      puts "Welcome to Twentyone!"
      please_press_enter
    end

    def good_bye
      puts "Goodbye!"
    end

    def present_match_winner
      puts "The match winner is #{score_keeper.match_winner}!"
    end
  end
end

TwentyOne::Game.new.start

# todo: add score_keeping with 2 rounds
# todo: fix dealer value (in partial view)
