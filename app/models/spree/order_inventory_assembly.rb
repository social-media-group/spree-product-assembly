module Spree
  # This class has basically the same functionality of Spree core OrderInventory
  # except that it takes account of bundle parts and properly creates and
  # removes inventory unit for each parts of a bundle
  class OrderInventoryAssembly < OrderInventory
    attr_reader :product

    def initialize(order, line_item)
      @order = order
      @line_item = line_item
      @product = line_item.product
    end

    def verify(shipment = nil, is_updated: false)
      return unless order.completed? || shipment.present?

      line_item_changed = is_updated ? !line_item.saved_changes? : !line_item.changed?
      line_item.quantity_by_variant.each do |part, total_parts|
        existing_parts = if Gem.loaded_specs['spree_core'].version >= Gem::Version.create('3.3.0')
                           line_item.inventory_units.where(variant: part).sum(&:quantity)
                         else
                           line_item.inventory_units.where(variant: part).count
                         end

        self.variant = part

        if existing_parts < total_parts
          quantity = total_parts - existing_parts

          shipment ||= determine_target_shipment
          add_to_shipment(shipment, quantity)
        elsif (existing_parts > total_parts) || (existing_parts == total_parts && line_item_changed)
          verify_remove_from_shipment(shipment, total_parts, existing_parts)
        end
      end
    end

    private

    def verify_remove_from_shipment(shipment, total_parts, existing_parts)
      quantity = existing_parts - total_parts

      if shipment.present?
        remove_from_shipment(shipment, quantity)
      else
        order.shipments.each do |shpment|
          break if quantity == 0

          quantity -= remove_from_shipment(shpment, quantity)
        end
      end
    end
  end
end
