module GameOfLife
  module Dimensions
    WIDTH = 90
    HEIGHT = 30
  end

  class Seed
    attr_accessor :string, :header, :body

    def initialize(seed_string)
      @string = seed_string
      @header, @body = extract_body_and_header
    end

    def extract_body_and_header
      lines = string.split("\n")
      header = ""
      body = ""
      lines.each do |line|
        line[0] == "!" ? header << (line + "\n") : body << (line + "\n")
      end
      [header, body]
    end

    # todo: this is madness
    def normalize(body)
      matrix = body.split("\n").map { |row| row.split("") }
      matrix_height = matrix.size
      matrix_width = matrix.first.size
      number_of_row_wraps = (Dimensions::HEIGHT - matrix_height) / 2
      dead_row = (Citizen::DEAD * matrix_width).split("")
      number_of_row_wraps.times do
        matrix = [dead_row] + matrix + [dead_row]
      end
      matrix.map(&:join).join("\n")

      # at this point, the matrix has the correct height, but not width.
      # what's the best strategy for resizing a matrix?
      # 1) append and prepend
      # 2) create an empty matrix of appropriate dimensions
      #    and carry over the values
      # => it looks like (2) might be better.
      # number_of_col_wraps = (WIDTH - matrix_width) / 2
      # # now we need to shift and push, which is sort of more tedious
    end

    def to_grid
      body.split("\n")
          .map { |line| line.split("") }
          .map { |row| row.map { |char| Citizen.new(char) } }
    end
  end

  class Citizen
    ALIVE = 'O'
    DEAD = '.'

    ALIVE_DISPLAY = "\u25FD".encode('utf-8')
    DEAD_DISPLAY = "\u25FE".encode('utf-8')

    attr_accessor :status, :location, :neighbors

    def initialize(status)
      @status = status
      @location = nil
      @neighbors = nil
    end

    def x
      location.first
    end

    def y
      location.last
    end

    def dead?
      status == DEAD
    end

    def alive?
      status == ALIVE
    end

    def alive_count
      neighbors.select { |neighbor| neighbor.alive? }.count
    end

    def to_s
      (alive? ? ALIVE_DISPLAY : DEAD_DISPLAY) #+ location.inspect
    end
  end

  class Population
    attr_accessor :grid, :citizens

    def initialize(grid)
      @grid = grid

      populate_citizens_list
      cache_citizen_locations
      cache_citizen_neighbors
    end

    def populate_citizens_list
      @citizens = []
      grid.each do |row|
        row.each do |citizen|
          citizens << citizen
        end
      end
    end

    def cache_citizen_locations
      grid.each_with_index do |row, row_idx|
        row.each_with_index do |citizen, col_idx|
          citizen.location = [col_idx, row_idx]
        end
      end
    end

    # todo: simplify
    def cache_citizen_neighbors
      citizens.each do |citizen|
        x = citizen.x
        y = citizen.y

        xplus1 = (x + 1) % grid.first.size
        yplus1 = (y + 1) % grid.size

        citizen.neighbors =
          [
            grid[y - 1][x - 1], grid[y - 1][x], grid[y - 1][xplus1],
            grid[y][x - 1], grid[y][xplus1],
            grid[yplus1][x - 1], grid[yplus1][x], grid[yplus1][xplus1]
          ]
      end
    end

    def change
      citizens.each do |citizen|
        if citizen.alive_count == 2
          true
        elsif citizen.alive_count == 3
          citizen.status = Citizen::ALIVE
        else
          citizen.status = Citizen::DEAD
        end
      end
    end

    def to_s
      grid.map(&:join).join("\n")
    end

  end

  class Game
    attr_accessor :seed, :population

    def initialize(seed_string)
      @seed = Seed.new(seed_string)
      @population = Population.new(seed.to_grid)
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
    end
  end
end

# Tests

# Testing Setup
# source for seed string:
# https://github.com/durden/pylife/blob/master/seed_files/A_for_all.cells

seed_string = <<END_HEREDOC
!Name: A_for_all
!
....OO....
...O..O...
...OOOO...
.O.O..O.O.
O........O
O........O
.O.O..O.O.
...OOOO...
...O..O...
....OO....
END_HEREDOC

game = GameOfLife::Game.new(seed_string)
# game.play
puts game.population
game.population.change
puts ""
puts game.population
# game.population.change
# puts ""
# puts game.population
# puts game.population.neighbors(game.population.grid[3][3])
