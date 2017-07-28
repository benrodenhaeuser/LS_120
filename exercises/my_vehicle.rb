require 'time'

class MyVehicle
  attr_accessor :color, :speed
  attr_reader :year, :model

  @@number_of_vehicles = 0

  def self.number_of_vehicles
    @@number_of_vehicles
  end

  def initialize(year, color, model)
    @year = year
    @color = color
    @model = model
    @speed = 0
    @@number_of_vehicles += 1
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

  def age
    calculate_age
  end

  private

  def calculate_age
    time = Time.new
    time.year - year
  end

end


module Trunk

  def open_trunk
    "The trunk is now open."
  end

  def close_trunk
    "The trunk is now closed."
  end

end


class MyCar < MyVehicle
  include Trunk

  NUMBER_OF_WHEELS = 4

  def to_s
    "Your car is a #{color} #{year} #{model}, currently driving at #{speed} miles per hour."
  end

end

class MyTruck < MyVehicle
  NUMBER_OF_WHEELS = 8

  def to_s
    "Your truck is a #{color} #{year} #{model}, currently driving at #{speed} miles per hour."
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

puts MyVehicle.number_of_vehicles # no print-out

truck = MyTruck.new(1970, 'white', 'Scania')

puts truck

puts MyVehicle.number_of_vehicles # no print-out

puts car.open_trunk

puts "Ancestors of MyCar:"
puts MyCar.ancestors

puts "Ancestors of MyTruck:"
puts MyTruck.ancestors

puts

puts car.age
puts truck.age

# puts car.calculate_age # NoMethodError, private method called
