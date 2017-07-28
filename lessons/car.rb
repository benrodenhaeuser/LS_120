module Speed
  def go_fast
    puts "I am a #{self.class} and going super fast!"
  end
end

class Car
  include Speed
  def go_slow
    puts "I am safe and driving slow."
  end
end

class Truck
  include Speed
  def go_very_slow
    puts "I am a heavy truck and like going very slow."
  end
end

car = Car.new
car.go_fast

Truck.new.go_fast

# go_fast is an instance method. So within go_fast, self evaluates to the object on which go_fast is called. On line 24, a Truck object calls go_fast. So self evaluates to that Truck object. But the class of the Truck object is (obviously) Truck. We don't need to call to_s on self.class, because this is taken care of by the string interpolation. 
