# Create a class called MyCar. When you initialize a new instance or object of the class, allow the user to define some instance variables that tell us the year, color, and model of the car. Create an instance variable that is set to 0 during instantiation of the object to track the current speed of the car as well. Create instance methods that allow the car to speed up, brake, and shut the car off.

class MyCar
  attr_accessor :color, :speed
  attr_reader :year, :model

  def initialize(year, color, model)
    @year = year
    @color = color
    @model = model
    @speed = 0
  end

  def speed_up(amount)
    @speed += amount
  end

  def brake(amount)
    @speed -= amount
  end

  def shut_off
    @speed = 0
  end

  def spray_paint(color)
    self.color = color
  end

  def to_s
    "Your car is a #{color} #{year} #{model}, currently driving at #{speed} miles per hour."
  end

end

car = MyCar.new(1965, 'green', 'Ford Mustang')
puts car.speed
car.speed_up(130)
puts car.speed
car.brake(30)
puts car.speed
car.shut_off
puts car.speed

puts car.year
puts car.color
car.spray_paint('yellow')
puts car.color
# car.year = 1990 # undefined method
puts car
