class AngryCat
  def initialize(age, name)
    @age  = age
    @name = name
  end

  def age
    puts @age
  end

  def name
    puts @name
  end

  def hiss
    puts "Hisssss!!!"
  end
end

camillo = AngryCat.new(8, "camillo")
pepa = AngryCat.new(8, "pepa")
p camillo #<AngryCat:0x007fc6b7045d50 @age=8, @name="camillo">
p pepa #<AngryCat:0x007fc6b7045c10 @age=8, @name="pepa">
