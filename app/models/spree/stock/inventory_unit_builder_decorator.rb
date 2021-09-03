module Spree
  module Stock
    module InventoryUnitBuilderDecorator
      def units
        @order.line_items.flat_map do |line_item|
          mapped_line_items = line_item.quantity_by_variant.flat_map do |variant, quantity|
            if Gem.loaded_specs['spree_core'].version >= Gem::Version.create('4.1.0')
              build_inventory_unit(variant, line_item, quantity)
            elsif Gem.loaded_specs['spree_core'].version >= Gem::Version.create('3.3.0')
              build_inventory_unit_3_3_0(variant, line_item, quantity)
            else
              quantity.times.map { build_inventory_unit(variant, line_item) }
            end
          end

          if line_item&.product&.assembly?
            # We also want to track the main sku.
            mapped_line_items << build_inventory_unit(line_item.variant, line_item, line_item.quantity)
          end

          mapped_line_items
        end
      end

      def build_inventory_unit(variant, line_item, quantity=nil)
        # They go through multiple splits, avoid loading the
        # association to order until needed.
        Spree::InventoryUnit.new(
          pending: true,
          line_item_id: line_item.id,
          variant_id: variant.id,
          quantity: quantity,
          order_id: @order.id
        )
      end

      def build_inventory_unit_3_3_0(variant, line_item, quantity=nil)
        @order.inventory_units.includes(
          variant: {
            product: {
              shipping_category: {
                shipping_methods: [:calculator, { zones: :zone_members }]
              }
            }
          }
        ).build(
          pending: true,
          variant: variant,
          line_item: line_item,
          order: @order
        ).tap do |iu|
          iu.quantity = quantity if quantity
        end
      end
    end
  end
end

Spree::Stock::InventoryUnitBuilder.prepend Spree::Stock::InventoryUnitBuilderDecorator
