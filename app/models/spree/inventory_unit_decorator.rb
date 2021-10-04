module Spree::InventoryUnitDecorator
  def percentage_of_line_item
    product = line_item.product
    if product.assembly?
      variants = line_item.quantity_by_variant.delete_if{|x| x == line_item.variant}
      total_value = variants.map { |part, quantity| part.price * quantity }.sum
      variant.price / total_value
    else
      quantity / BigDecimal(line_item.quantity)
    end
  end
end

Spree::InventoryUnit.prepend Spree::InventoryUnitDecorator
