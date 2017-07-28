class InvoiceEntry
  attr_reader :product_name
  attr_accessor :quantity

  def initialize(product_name, number_purchased)
    @quantity = number_purchased
    @product_name = product_name
  end

  def update_quantity(updated_count)
    # prevent negative quantities from being set
    self.quantity = updated_count if updated_count >= 0
  end
end

# mistake: need to call quantity with explicit receiver self
# there won't be an error, but the @quantity ivar will not be set

entry = InvoiceEntry.new("name", 2)
entry.update_quantity(100)
p entry.quantity # => 2

# to fix it call quantity on self and create accessor for quantity
