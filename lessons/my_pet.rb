class MyPet
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def speak
    puts self
    "#{name} says: Hello!"
  end
end

my_pet = MyPet.new("Camillo")
puts my_pet.speak # Camillo says: Hello!

array = [1, 2, 3]

def array.my_method
  each { |elem| puts elem }
end

array.my_method
