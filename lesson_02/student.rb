class Student
  attr_accessor :name
  attr_writer :grade

  def initialize(name, age)
    @name = name
    @age = age
    @grade = nil
  end
end

jon = Student.new('John', 22)
p jon.name # => 'John'
jon.name = 'Jon'
jon.grade = 'B'
p jon.grade # => 'B'
