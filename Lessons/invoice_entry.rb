class InvoiceEntry
  attr_accessor :quantity, :product_name

  def initialize(product_name, number_purchased)
    @quantity = number_purchased
    @product_name = product_name
  end

  def update_quantity(updated_count)
    self.quantity = updated_count if updated_count >= 0
  end
end

# we have changed the interface for both quantity and product_name instance variable. They now also has a setter which is part of the public interface of the InvoiceEntry class.
