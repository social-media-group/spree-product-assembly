module Spree
  module Stock
    module PrioritizerDecorator
      def hash_item(item)
        shipment = item.inventory_unit.shipment
        variant  = item.inventory_unit.variant
        line_item  = item.inventory_unit.line_item

        hash = if shipment.present?
                 variant.hash ^ shipment.hash
               else
                 variant.hash
               end

        hash ^ line_item.hash if line_item.present?
      end
    end
  end
end

Spree::Stock::Prioritizer.prepend Spree::Stock::PrioritizerDecorator
