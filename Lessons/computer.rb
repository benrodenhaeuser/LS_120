class Computer
  attr_accessor :template

  def create_template
    @template = "template 14231"
  end

  def show_template
    template
  end
end

class Computer
  attr_accessor :template

  def create_template
    self.template = "template 14231"
  end

  def show_template
    self.template
  end
end

# what is the difference?
# there is no difference in behaviour.
# in the first version, `create_template` accesses the instance variable @template directly and assigns the string "template 14231" to the ivar.
# in the second version, `create_template` uses the setter method (which is available as per line 2) template= to assign to the instance variable.
# That is, while line 5 is an assignment, line 17 is a method call.
# Notice that the `self` in line 17 is non-optional.

# The difference between line 21 and line 9, on the other hand, is merely one of notation. In both cases, the getter is used to retrieve the value of the ivar. In one case, the getter is called explicitly on `self` (line 9), in the second case the getter is called implicitly on `self` (line 21). Line 21 would generate a Rubocop style complaint.  
