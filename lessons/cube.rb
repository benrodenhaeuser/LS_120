class Cube
  # attr_accessor :volume

  def initialize(volume)
    @volume = volume
  end

  def get_volume
    @volume
  end

end

p Cube.new(500).get_volume

Cube.new(5000).instance_variable_get("@volume")
