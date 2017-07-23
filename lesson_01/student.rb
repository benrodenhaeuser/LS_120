class Student

  attr_accessor :name

  def initialize(name, grade)
    @name = name
    @grade = grade
  end

  def better_grade_than?(other_student)
    @grade > other_student.grade
  end

  protected

  def grade
    @grade
  end

end

bob = Student.new('bob', 100)
tom = Student.new('tom', 90)

puts bob.better_grade_than?(tom)
