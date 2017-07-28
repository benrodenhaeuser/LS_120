class Pet
  def run
    'running!'
  end

  def jump
    'jumping!'
  end

end

class Dog < Pet

  def swim
    'swimming!'
  end

  def fetch
    'fetching!'
  end

  def speak
    'bark!'
  end
end

class Cat < Pet
  def speak
    'meow!'
  end
end

teddy = Dog.new
puts teddy.run
puts teddy.jump
puts teddy.speak
puts teddy.swim
puts teddy.fetch

camillo = Cat.new
puts camillo.run
puts camillo.jump
puts camillo.speak
puts camillo.swim # undefined method
