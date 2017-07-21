# good_dog.rb

class GoodDog
  attr_accessor :name, :height, :weight

  puts self # here, self references the class

  # attr_reader for read-access
  # attr_writer for write-access

  def initialize(name, height, weight)
    self.name = name # here, self references the instance
    self.height = height
    self.weight = weight
  end

  # getter and setter below are provided by attr_accessor above

  # def name # getter
  #   @name
  # end

  # def name=(name) # setter (note the "weird" syntax!)
  #   @name = name
  # end

  # ^ the '=' in the method name is significant! it's has consequences behind
  #   the scenes. contrast this with having a bang in a method name, which is
  #   just a conventional device

  def speak
    "#{name} says wuff!"
  end

  def change_info(dog_name, dog_height, dog_weight)
    self.name = dog_name # without self, Ruby thinks we are creating local variables
    self.height = dog_height
    self.weight = dog_weight
  end

  def info
    "The name is: #{self.name}. The height is: #{self.height}. The weight is: #{self.weight}."
  end
  # ^ above, we wouldn't have had to use self. Ruby will not get confused
  #   either way

end

# tests

GoodDog
sparky = GoodDog.new('sparky', 'initial height', 'initial weight')
puts sparky.speak
puts sparky.info
sparky.change_info('spartacus', 'new height', 'new weight')
puts sparky.info
