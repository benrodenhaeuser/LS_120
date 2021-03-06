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
      (alive? ? Status::ALIVE : Status::DEAD)
    end
  end

  class Population
    # todo: my feeling is that it would be easier to understand this if we did
    # everything just with a "normal" grid representation. We can always derive a citizens list by flattening the grid.
    # what's not possible then is to have Index objects like we did above.
    # what we could still do is cache the neighbors. 

    def initialize(seed_grid)
      @display_grid = seed_grid
      @citizens = {}
      display_grid.each_with_index do |row, row_index|
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

    def to_s
      update_display_grid
      display_string
    end

    private

    attr_accessor :citizens, :display_grid

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
      [
        self[x - one, y - one], self[x - one, y], self[x - one, y + one],
        self[x, y - one], self[x, y + one],
        self[x + one, y - one], self[x + one, y], self[x + one, y + one]
      ]
    end

    def [](col_obj, row_obj)
      citizens[[col_obj, row_obj]]
    end

    def update_display_grid
      citizens.each do |location, citizen|
        display_grid[location.last.value][location.first.value] = citizen.to_s
      end
    end

    def display_string
      display_grid.map(&:join).join("\n")
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
