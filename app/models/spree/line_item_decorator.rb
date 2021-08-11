module Spree::LineItemDecorator
  def self.prepended(base)
    base.scope :assemblies, -> { joins(product: :parts).distinct }
    base.has_many :part_line_items, dependent: :destroy

    base.before_destroy :verify_order_assembly_inventory_before_destroy, if: -> { order.has_checkout_step?('delivery') }
  end

  def any_units_shipped?
    inventory_units.any? { |unit| unit.shipped? }
  end

  def parts
    product.parts
  end

  def count_of(variant)
    product.count_of(variant)
  end

  def quantity_by_variant
    if product.assembly?
      if part_line_items.any?
        quantity_with_part_line_items(quantity)
      else
        quantity_without_part_line_items(quantity)
      end
    else
      { variant => quantity }
    end
  end

  private

  def update_inventory
    if product.assembly?
      if (saved_changes? || target_shipment.present?) && order.has_checkout_step?('delivery')
        verify_order_assembly_inventory
      end
    else
      super
    end
  end

  def verify_order_assembly_inventory
    Spree::OrderInventoryAssembly.new(order, self).verify(target_shipment, is_updated: true)
  end

  def verify_order_assembly_inventory_before_destroy
    Spree::OrderInventoryAssembly.new(order, self).verify(target_shipment)
  end

  def quantity_with_part_line_items(quantity)
    part_line_items.each_with_object({}) do |ap, hash|
      hash[ap.variant] = ap.quantity * quantity
    end
  end

  def quantity_without_part_line_items(quantity)
    product.assemblies_parts.each_with_object({}) do |ap, hash|
      hash[ap.part] = ap.count * quantity
    end
  end
end

Spree::LineItem.prepend Spree::LineItemDecorator
