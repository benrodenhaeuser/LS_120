module GameOfLife
  module Size
    HEIGHT = 10 # set to the size of the seed
    WIDTH = 10 # set to the size of the seed
  end

  module Status
    require 'colorize'

    ALIVE = "\u25FD".colorize(:red)
    DEAD = "\u25FE"
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

    def initialize(status)
      @status =
        case status
        when 'O' then Status::ALIVE
        when '.' then Status::DEAD
        end
      @next_status = nil
    end

    def alive?
      status == Status::ALIVE
    end

    def to_s
      (alive? ? Status::ALIVE : Status::DEAD) # not used right now.
    end
  end

  class Population
    def initialize(seed_grid)
      @citizens = {}
      seed_grid.each_with_index do |row, row_index|
        row.each_with_index do |status, col_index|
          citizens[[ColIndex.new(col_index), RowIndex.new(row_index)]] =
            Citizen.new(status)
        end
      end
    end

    def change
      calculate_next_status
      update_current_status
    end

    # this builds a grid, whereas if we just use the seed grid, we can take it for granted.
    def to_s
      grid = []
      (0...Size::HEIGHT).each do |row_idx|
        row = []
        (0...Size::WIDTH).each do |col_idx|
          row << self[col_idx, row_idx].status
        end
        grid << row
      end

      grid.map(&:join).join("\n")
    end

    private

    attr_accessor :citizens, :grid

    def calculate_next_status
      citizens.each_value do |citizen|
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
      citizens.each_value do |citizen|
        citizen.status = citizen.next_status
        citizen.next_status = nil
      end
    end

    def live_neighbors(citizen)
      neighbors(citizen).select(&:alive?)
    end

    def neighbors(citizen)
      location = citizens.key(citizen)
      x = location.first
      y = location.last
      one = Index.new(1)

      # todo: this is the only place where we need the Index class.
      # is this really a reasonable design then?

      [
        self[x - one, y - one], self[x - one, y], self[x - one, y + one],
        self[x, y - one], self[x, y + one],
        self[x + one, y - one], self[x + one, y], self[x + one, y + one]
      ]
    end

    def [](col_idx, row_idx)
      # todo: this allows to index into the hash with both ints and Index objs.
      # which is nice ... but but I am not sure if this is a good idea?
      # it's yet more complexity that ultimately comes from the neighbors method
      # would it be possible to do this without a type check?
      if col_idx.is_a?(Integer)
        citizens[[ColIndex.new(col_idx), RowIndex.new(row_idx)]]
      else
        citizens[[col_idx, row_idx]]
      end
    end

    def update_grid
      citizens.each do |location, citizen|
        grid[location.last.value][location.first.value] = citizen.status
      end
    end

    def display_string
      grid.map(&:join).join("\n")
    end

  end

  class Seed
    attr_accessor :string, :header, :body

    def initialize(seed_string)
      @string = seed_string
      @header, @body = header_and_body
    end

    def to_grid
      body.split("\n").map { |line| line.split("") }
    end

    private

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

    def expand
      # todo
    end

  end

  class Game
    attr_accessor :seed, :population

    def initialize(seed_string)
      @seed = Seed.new(seed_string)
      @population = Population.new(seed.to_grid)
    end

    def play
      20.times do
        display
        change
      end
    end

    private

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

# puts GameOfLife::Status::ALIVE

# todos:

# - maybe have a "real" torus class? (with an "origin") that subsumes the grid
#   and the citizens list
