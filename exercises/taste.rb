module Taste
  def flavor(flavor)
    puts "#{flavor}"
  end
end

class Orange
  include Taste
end

class HotSauce
  include Taste
end

p HotSauce.ancestors


# Orange > Taste > Object > ...
# HotSauce > Taste > Object > ...


# class methods start with `self` in the method definition
# they are called directly on the class object (i.e., use the class name, followed by dot, followed by name of the method).

# example:

class Animal
  @@number_of_animals = 10

  def self.number_of_animals
    @@number_of_animals
  end
end

p Animal.number_of_animals # => 10
