# the matrix indices are not "width_indices" and "height_indices"
# they are integers
# so we need to build a "true" matrix class which uses widths and heights
# in the way required.


# hash { [x, y] => citizen }

def citizen(x, y) # the citizen that lives at x, y
  citizens.find { |citizen| citizen.x == x && citizen.y == y }
end

# inefficientq




class TorusMatrix

  def initialize(matrix)
    @matrix = matrix # what is this?
    @width = width
    @height = height
  end

  def

  end

end



class WidthIndex

  @@width = 40

  attr_accessor :val

  def initialize(val)
    @val = val
  end

  def +(other)
    (val + other.val) % @@width
  end

  def -(other)
    (val - other.val) % @@width
end

class HeightIndex

  @@width = 30

  attr_accessor :val

  def initialize(val)
    @val = val
  end

  def +(other)
    (val + other.val) % @@height
  end

  def -(other)
    (val - other.val) % @@height
end

x = Width.new(10)
y = Width.new(33)

p x + y
p x - y
