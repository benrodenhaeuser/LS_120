module GameOfLife
  module Size
    HEIGHT = 10 # set to the size of the seed
    WIDTH = 10 # set to the size of the seed
  end

  module Status
    ALIVE = 'O'
    DEAD = '.'
  end

  module Display
    ALIVE = "\u25FD".encode('utf-8')
    DEAD = "\u25FE".encode('utf-8')
  end

  class Index
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      value == other.value
    end

    def eql?(other)
      self == other
    end

    def hash
      value.hash
    end
  end

  class ColIndex < Index
    def +(other)
      RowIndex.new((value + other.value) % Size::WIDTH)
    end

    def -(other)
      RowIndex.new((value - other.value) % Size::WIDTH)
    end
  end

  class RowIndex < Index
    def +(other)
      RowIndex.new((value + other.value) % Size::HEIGHT)
    end

    def -(other)
      RowIndex.new((value - other.value) % Size::HEIGHT)
    end
  end

  class Citizen
    attr_accessor :status, :next_status

    def initialize(status, col_idx, row_idx)
      @status = status
      @next_status = nil
      @row_idx = row_idx # just for testing
      @col_idx = col_idx # just for testing
    end

    def alive?
      status == Status::ALIVE
    end

    def to_s
      (alive? ? Display::ALIVE : Display::DEAD) # not used right now.
    end
  end

  class Population
    # todo: need to expand "seed grid" to desired grid size

    attr_accessor :citizens_hash, :grid

    def initialize(seed_grid)
      @grid = expand_to_size(seed_grid)
      @citizens_hash = {}
      grid.each_with_index do |row, row_index|
        row.each_with_index do |status, col_index|
          citizens_hash[[ColIndex.new(col_index), RowIndex.new(row_index)]] =
            Citizen.new(status, col_index, row_index)
        end
      end
    end

    def expand_to_size(grid)
      grid # todo
    end

    def neighbors(citizen)
      location = citizens_hash.key(citizen)
      x = location.first # the col
      y = location.last # the row
      one = Index.new(1)

      [
        # col to the left
        self[x - one, y - one], self[x - one, y], self[x - one, y + one],
        # same col
        self[x, y - one], self[x, y + one],
        # col below
        self[x + one, y - one], self[x + one, y], self[x + one, y + one]
      ]
      # printing the neighbors makes things look ok.
    end

    # this doesn't help anyone, it just makes code harder to read.
    def [](x, y)
      citizens_hash[[x, y]]
    end

    def live_neighbors(citizen)
      neighbors(citizen).select(&:alive?)
    end

    def change
      calculate_next_status
      update_current_status
    end

    def calculate_next_status
      citizens_hash.each do |location, citizen|
        citizen.next_status =
          if live_neighbors(citizen).count == 2
            citizen.status
          elsif live_neighbors(citizen).count == 3
            Status::ALIVE
          else
            Status::DEAD
          end
      end
    end

    def update_current_status
      citizens_hash.each do |location, citizen|
        citizen.status = citizen.next_status
        citizen.next_status = nil
      end
    end

    def update_grid #
      citizens_hash.each do |location, citizen|
        grid[location.last.value][location.first.value] = citizen.status
        # location.last is the row, location.first is the col
      end
    end

    def to_s
      update_grid
      grid.map(&:join).join("\n") # todo: this uses . and O right now.
    end
  end

  class Seed
    attr_accessor :string, :header, :body

    def initialize(seed_string)
      @string = seed_string
      @header, @body = header_and_body
    end

    def header_and_body
      lines = string.split("\n")

      header = ""
      body = ""

      lines.each do |line|
        if line[0] == "!"
          header << (line + "\n")
        else
          body << (line + "\n")
        end
      end

      [header, body]
    end

    def to_matrix
      body.split("\n").map { |line| line.split("") }
    end
  end

  class Game
    attr_accessor :seed, :population

    def initialize(seed_string)
      @seed = Seed.new(seed_string)
      @population = Population.new(seed.to_matrix)
    end

    def play
      20.times do
        display
        change
      end
    end

    def display
      system 'clear'
      puts population
    end

    def change
      population.change
      sleep 0.3
    end
  end
end

# seed_string = <<END_HEREDOC
# !Name: A_for_all
# !
# ....OO....
# ...O..O...
# ...OOOO...
# .O.O..O.O.
# O........O
# O........O
# .O.O..O.O.
# ...OOOO...
# ...O..O...
# ....OO....
# END_HEREDOC

seed_string = <<END_HEREDOC
!Name: Glider
!
..........
..........
..........
..........
....O.....
.....O....
...OOO....
..........
..........
..........
END_HEREDOC

GameOfLife::Game.new(seed_string).play
# puts game.population
# puts ""
# game.population.change
# puts game.population

# p game.population # population object looks good
# puts ""
# puts game.population.citizens_hash
# puts ""
# puts game.population.to_s # string looks good
# puts ""
# game.population.change # goes through
# puts game.population.to_s # looks promising, but hard to be sure
