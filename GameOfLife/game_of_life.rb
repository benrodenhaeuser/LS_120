module GameOfLife
  module Dimensions
    WIDTH = 40
    HEIGHT = 20
  end

  class Citizen
    ALIVE = 'O'
    DEAD = '.'

    ALIVE_DISPLAY = "\u25FD".encode('utf-8')
    DEAD_DISPLAY = "\u25FE".encode('utf-8')

    attr_accessor :status, :next_status, :location, :neighbors

    def initialize(status)
      @status = status
      @next_status = nil # todo: to be computed :-)
      @location = nil # [x, y]
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
      neighbors.select(&:alive?).count
    end

    def to_s
      (alive? ? ALIVE_DISPLAY : DEAD_DISPLAY) #+ location.inspect
    end
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
    # todo: code only works if seed has even width!
    def normalize(body)
      lines = body.split("\n")
      width = lines.first.length
      number_of_syms_to_wrap = (Dimensions::WIDTH - width) / 2
      syms_string = Citizen::DEAD * number_of_syms_to_wrap
      horiz_wrapped = lines.map { |line| syms_string + line + syms_string }

      matrix = horiz_wrapped.map { |row| row.split("") }
      height = matrix.size

      number_of_row_wraps = (Dimensions::HEIGHT - height) / 2
      dead_row = (Citizen::DEAD * Dimensions::WIDTH).split("")
      number_of_row_wraps.times do
        matrix = [dead_row] + matrix + [dead_row]
      end
      matrix.map(&:join).join("\n")
    end

    def to_grid
      normalize(body)
        .split("\n")
        .map { |line| line.split("") }
        .map { |row| row.map { |char| Citizen.new(char) } }
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

    # todo: complicated
    def cache_citizen_neighbors
      citizens.each do |citizen|
        x = citizen.x # col idx of citizen
        y = citizen.y # row idx of citizen

        num_of_cols = grid.first.size
        num_of_rows = grid.size

        xplus1 = (x + 1) % num_of_cols
        yplus1 = (y + 1) % num_of_rows

        citizen.neighbors =
          [
            grid[y - 1][x - 1], grid[y - 1][x], grid[y - 1][xplus1],
            grid[y][x - 1], grid[y][xplus1],
            grid[yplus1][x - 1], grid[yplus1][x], grid[yplus1][xplus1]
          ]
      end
    end

    def change
      cache_next_status
      update_current_status
    end

    def cache_next_status
      citizens.each do |citizen|
        citizen.next_status =
          if citizen.alive_count == 2
            citizen.status
          elsif citizen.alive_count == 3
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
      100.times do # todo: make this configurable (or stoppable)
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

# Tests

# Testing Setup
# source for seed string:
# https://github.com/durden/pylife/blob/master/seed_files/A_for_all.cells
#
# many seed files: https://github.com/durden/pylife/tree/master/seed_files

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

# seed_string = <<END_HEREDOC
# !Name: Glider
# !
# .O..
# ..O.
# OOO.
# END_HEREDOC

GameOfLife::Game.new(seed_string).play

# todo:
# we are essentially using two representations:
# - the grid representation
# - the citizen list representation
# is that wise?
# we could cache data in individual citizens even if we had no citizens list.
