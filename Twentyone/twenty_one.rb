module TwentyOne
  class Card
    attr_reader :name, :suit, :raw_value

    def initialize(name, suit, raw_value)
      @name = name
      @raw_value = raw_value
      @suit = suit
    end

    def to_s
      wrapper  = ("+" + ("-" * 7) + "+")
      filler   = "|" + (" " * 7) + "|"
      suit_str = "|" + suit.center(7) + "|"
      name_str = "|" + name.center(7) + "|"

      [wrapper, filler, suit_str, name_str, filler, wrapper].join("\n")
    end
  end

  class Deck
    SUITS =
      [
        "\u2660".encode('utf-8'), # spades
        "\u2663".encode('utf-8'), # clubs
        "\u2665".encode('utf-8'), # hearts
        "\u2666".encode('utf-8')  # diamonds
      ]
    NUMBERS = (2..10)
    FACES = ['J', 'Q', 'K']
    ACE = 'A'

    def initialize
      @stock = initial_card_stock.shuffle
    end

    def initial_card_stock
      cards = []
      SUITS.each do |suit|
        NUMBERS.each { |value| cards << Card.new(value.to_s, suit, value) }
        FACES.each { |face| cards << Card.new(face, suit, 10) }
        cards << Card.new(ACE, suit, 11)
      end
      cards
    end

    def deal_a_card(participant)
      participant << stock.pop
    end

    def reset
      initialize
    end

    private

    attr_reader :stock
  end

  class Hand
    include Enumerable

    def initialize
      @cards = []
    end

    def each(&block)
      cards.each(&block)
    end

    def <<(card)
      cards << card
    end

    def value
      value = map(&:raw_value).inject(&:+)
      number_of_aces.times { value -= 10 if value >= Participant::BUST_VALUE }
      value
    end

    def number_of_aces
      select { |card| card.name == Deck::ACE }.count
    end

    def value_of_first_card
      cards.first.raw_value
    end

    def partially_hidden
      partial_hand = Hand.new
      face_down_card = Card.new('?', '?', nil)
      partial_hand << cards.first << face_down_card
      partial_hand
    end

    def to_s
      map { |card| card.to_s.split("\n") }
        .transpose
        .map { |line| line.join(' ') }
        .join("\n")
    end

    private

    attr_reader :cards
  end

  class Participant
    BUST_VALUE = 22

    attr_accessor :hand

    def initialize
      @hand = Hand.new
    end

    def <<(card)
      hand << card
    end

    def hit(deck)
      deck.deal_a_card(self)
    end

    def busted?
      hand.value >= BUST_VALUE
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
      hand.value >= DEALER_STAY_VALUE
    end

    def to_s
      "Dealer"
    end
  end

  module ShowHands
    private

    def show_hands
      system 'clear'
      puts ""
      puts hands_string
      puts ""
    end

    def hands_string
      [hand_string(player), hand_string(dealer)].join("\n\n")
    end

    def hand_string(participant)
      name_chars = participant.to_s.upcase.split("")
      hand_lines = hand(participant).to_s.split("\n")
      value_lines = ["", "", *hand_value_to_show(participant), "", ""]

      [name_chars, hand_lines, value_lines]
        .transpose
        .map { |line| line.join(" " * 5) }
        .join("\n")
    end

    def hand(participant)
      if participant == dealer && !finished
        participant.hand.partially_hidden
      else
        participant.hand
      end
    end

    def hand_value_to_show(participant)
      if participant == dealer && !finished
        ["", ""]
      elsif participant.busted?
        ["total:", "#{participant.hand.value} (BUSTED!!)"]
      else
        ["total", participant.hand.value.to_s]
      end
    end
  end

  module Prompt
    private

    def prompt(message)
      puts((" " * 4) + "> " + message)
    end

    def print_indent
      print " " * 6
    end

    def announce_invalid_input
      prompt "Sorry, this is not a valid input."
    end

    def request_to_press_enter
      prompt "Press enter to continue."
      print_indent
      gets
    end

    def request_to_continue_or_exit
      prompt "Press enter to continue (or (e) to exit)."
      print_indent
      decision = gets.chomp.to_s.downcase
      return decision if ['', 'e'].include?(decision)
      announce_invalid_input
      request_to_continue_or_exit
    end
  end

  class Round
    include ShowHands, Prompt

    attr_reader :winner

    def initialize(player, dealer)
      @player = player
      @dealer = dealer
      @deck = Deck.new
      @finished = false
      @winner = nil
    end

    def play
      deal_two_cards_each
      player_turn
      dealer_turn
      evaluate_hands
      show_hands
      show_winner
    end

    private

    attr_accessor :finished
    attr_writer   :winner
    attr_reader   :player, :dealer, :deck

    def deal_two_cards_each
      [player, dealer].each do |participant|
        2.times { deck.deal_a_card(participant) }
      end
    end

    def player_turn
      show_hands
      return if player.busted?
      answer = request_decision
      return if answer.start_with?('s')
      player.hit(deck)
      player_turn
    end

    def request_decision
      prompt "Would you like to (h)it or (s)tay?"
      print_indent
      answer = gets.chomp.downcase
      return answer if answer.start_with?('h', 's')
      announce_invalid_input
      request_decision
    end

    def dealer_turn
      return if player.busted?
      dealer.hit(deck) until dealer.stay?
      self.finished = true
    end

    def evaluate_hands
      return if player.hand.value == dealer.hand.value
      self.winner = calculate_winner
    end

    def calculate_winner
      if player.busted?
        dealer
      elsif dealer.busted?
        player
      else
        [player, dealer].max_by { |participant| participant.hand.value }
      end
    end

    def show_winner
      if winner
        prompt "#{winner} wins this round!"
      else
        prompt "It's a tie."
      end
    end
  end

  class Match
    ROUNDS_TO_WIN = 3

    include Prompt

    def initialize
      @player = Player.new
      @dealer = Dealer.new
      @round = nil
      @winner = nil
      @scores = Hash.new { |hash, key| hash[key] = 0 }
    end

    def play
      reset_players
      play_round
      keep_score
      present_scores
      return if winner
      user_decides_to_continue
      play
    end

    protected

    attr_accessor :round, :winner

    private

    attr_reader :player, :dealer, :scores

    def play_round
      self.round = Round.new(player, dealer)
      round.play
    end

    def keep_score
      scores[round.winner] += 1
      self.winner = round.winner if scores[round.winner] == ROUNDS_TO_WIN
    end

    def reset_players
      [player, dealer].each(&:reset)
    end

    def present_scores
      prompt "#{player} #{scores[player]} : #{scores[dealer]} #{dealer}"
      prompt "#{winner} wins the match!" if winner
    end

    def user_decides_to_continue
      decision = request_to_continue_or_exit
      abort("Sad to see you go!") if decision == 'e'
    end
  end

  class Session
    include Prompt

    def initialize
      @match = nil
    end

    def start
      intro
      play
      outro
    end

    protected

    attr_accessor :match

    private

    def play
      play_match
      play if play_some_more?
    end

    def play_match
      self.match = Match.new
      match.play
    end

    def play_some_more?
      answer = nil
      loop do
        prompt "Would you like to play some more? (y/n)"
        print_indent
        answer = gets.chomp.downcase
        break if answer.start_with?('y', 'n')
        announce_invalid_input
      end
      answer.start_with?('y')
    end

    def intro
      system 'clear'
      puts ""
      prompt "Welcome to Twentyone!"
      prompt "It takes #{Match::ROUNDS_TO_WIN} round wins to win the match."
      request_to_press_enter
    end

    def outro
      prompt "Goodbye!"
    end
  end
end

TwentyOne::Session.new.start
