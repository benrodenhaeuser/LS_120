module Size
  HEIGHT = 20
  WIDTH = 30
end

module Status
  ALIVE = 'O'
  DEAD = '.'
end

# https://stackoverflow.com/questions/11247000/which-equality-test-does-rubys-hash-use-when-comparing-keys
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
    RowIndex.new((val + other.val) % Size::WIDTH)
  end

  def -(other)
    RowIndex.new((val - other.val) % Size::WIDTH)
  end
end

class RowIndex < Index
  @@height = Size::HEIGHT

  def +(other)
    RowIndex.new((val + other.val) % Size::HEIGHT)
  end

  def -(other)
    RowIndex.new((val - other.val) % Size::HEIGHT)
  end
end

index_object = ColIndex.new(10)
hash = Hash.new
hash[index_object] = "the value"
another_index_object = ColIndex.new(10)
p index_object == another_index_object #=> "the value"
p hash[another_index_object] #=> nil (!)

string_object = 'ben'
another_hash = Hash.new
another_hash[string_object] = "a value"
another_string_object = 'ben'
p string_object == another_string_object #=> true
p another_hash[another_string_object] #=> "a value"
