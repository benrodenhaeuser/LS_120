class Television
  def self.manufacturer
    # method logic
  end

  def model
    # method logic
  end
end

tv = Television.new
tv.manufacturer # no method error
tv.model # returns nil
Television.manufacturer # returns nil
Television.model # no method error
