class Fruit
  def initialize(name)
    name = name
  end
end

class Pizza
  def initialize(name)
    @name = name
  end
end

# Instances of the Pizza class have an instance variable `@name`, discernible by the `@` symbol (instance variables generally start with an `@`). Instances of the Fruit class do not have an instance variable.

p Pizza.new("cheese").instance_variables
p Fruit.new("apple").instance_variables
