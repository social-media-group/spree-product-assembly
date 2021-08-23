module Spree
  module Stock
    module PackerDecorator
      # Overriding the default packager
      def default_package
        package = Package.new(stock_location)

        # Group by variant_id as grouping by variant fires cached query.
        inventory_units.index_by do |unit|
          { variant_id: unit.variant_id, line_item_id: unit.line_item_id }
        end.each do |indices, inventory_unit|
          variant = Spree::Variant.find(indices[:variant_id])
          unit = inventory_unit.dup # Can be used by others, do not use directly

          if variant.should_track_inventory?
            next unless stock_location.stocks? variant

            on_hand, backordered = stock_location.fill_status(variant, unit.quantity)
            package.add(InventoryUnit.split(unit, backordered), :backordered) if backordered.positive?
            package.add(InventoryUnit.split(unit, on_hand), :on_hand) if on_hand.positive?
          else
            package.add unit
          end
        end

        package
      end
    end
  end
end

Spree::Stock::Packer.prepend Spree::Stock::PackerDecorator
