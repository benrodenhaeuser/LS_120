module GameOfLife
  module Size
    HEIGHT = 20
    WIDTH = 30
  end

  module Status
    ALIVE = 'O'
    DEAD = '.'
  end

  class Index
    attr_reader :val

    def initialize(val)
      @val = val
    end
  end

  class ColIndex < Index
    def +(other)
      (val + other.val) % Size::WIDTH
    end

    def -(other)
      (val - other.val) % Size::WIDTH
    end
  end

  class RowIndex < Index
    @@height = Size::HEIGHT

    def +(other)
      (val + other.val) % Size::HEIGHT
    end

    def -(other)
      (val - other.val) % Size::HEIGHT
    end
  end

  class Citizen
    ALIVE_DISPLAY = "\u25FD".encode('utf-8')
    DEAD_DISPLAY = "\u25FE".encode('utf-8')

    attr_accessor :x, :y, :status, :neighbors

    def initialize(status)
      @status = status
      @next_status = nil
    end

    def dead?
      status == Status::DEAD
    end

    def alive?
      status == Status::ALIVE
    end

    def live_neighbors_count
      neighbors.select(&:alive?).count
    end

    def to_s
      (alive? ? ALIVE_DISPLAY : DEAD_DISPLAY)
    end
  end

  class Population
    attr_accessor :population

    def initialize(matrix)
      citizens = matrix_to_citizens
    end

    def matrix_to_citizens
      # build citizens hash
      # keys are locations (pairs of Index objects)
      # values are citizens
    end

    def neighbors(citizen)
      [
        [x + 1, y + 1] # etc: use the index objects!
      ]
    end

    def live_neighbors(citizen)
      # select live neighbors from neighbors
    end

    # great
    def [](x, y)
      citizens[[x,y]]
    end

    def change
      calculate_next_status
      update_current_status
    end

    def calculate_next_status
      citizens.each do |citizen|
        citizen.next_status =
          if live_neighbors(citizen).count == 2
            citizen.status
          elsif live_neighbors(citizen).count == 3
            Citizen::ALIVE
          else
            Citizen::DEAD
          end
      end
    end

    def update_current_status
      citizens.each do |citizen|
        citizen.status = citizen.next_status
        citizen.next_status = nil
      end
    end

    def to_grid
      grid = # todo: need empty grid of appropriate size
      citizens.each do |location, citizen|
        grid[key.first.val][key.last.val] = value.status
      end
      grid
    end

    def to_s
      to_grid.map { |row| row.join }.join("\n")
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

    def to_matrix
      body.split("\n").map { |line| line.split("") }
    end
  end

  class Game
    attr_accessor :seed, :population

    def initialize(seed_string)
      @seed = Seed.new(seed_string)
      @population = Population.new(seed.to_citizens)
    end

    def play
      100.times do
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
      sleep 0.1
    end
  end
  end
end
