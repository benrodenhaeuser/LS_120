class Test
  attr_accessor :hash

  def initialize
    @hash = { [1, 2] => 3, [4, 5] => 6}
  end

  def [](x, y)
    hash[[x,y]]
  end

end

test = Test.new
p test[1, 2]
