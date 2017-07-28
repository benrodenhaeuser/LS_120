class Greeting
  def self.greet(message)
    puts message
  end
end

class Hello < Greeting
  def self.hi
    greet("Hello")
  end
end

class Goodbye < Greeting
  def bye
    greet("Goodbye")
  end
end

# hello = Hello.new
# hello.hi # => "Hello" is output
#
# hello = Hello.new
# hello.bye # => undefined method (NoMethodError)
#
# hello = Hello.new
# hello.greet # => wrong number of arguments (ArgumentError)
#
# hello = Hello.new
# hello.greet("Goodbye") # => "Goodbye" is output

Hello.hi # => undefined method (NoMethodError)
