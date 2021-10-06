module Spree::InventoryUnitDecorator
  def required_quantity
    return @required_quantity unless @required_quantity.nil?

    @required_quantity = if exchanged_unit?
                           original_return_item.return_quantity
                         else
                           if line_item.product.assembly?
                             part_count = if line_item.part_line_items.any?
                                            line_item.part_line_items
                                                     .where(variant_id: variant.id)
                                                     .sum(&:quantity)
                                          else
                                            line_item.product.assemblies_parts
                                                             .where(part_id: variant.id)
                                                             .sum(&:count)
                                          end

                             line_item.quantity * part_count
                           else
                             line_item.quantity
                           end
                         end
  end

  def percentage_of_line_item
    if line_item.product.assembly?
      variants = line_item.quantity_by_variant.delete_if{|x| x == line_item.variant}
      total_value = variants.map { |part, quantity| part.price * quantity }.sum
      variant.price / total_value
    else
      quantity / BigDecimal(line_item.quantity)
    end
  end
end

Spree::InventoryUnit.prepend Spree::InventoryUnitDecorator
