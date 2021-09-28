module Spree
  module Stock
    # Overridden from spree core to make it also check for assembly parts stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        line_item.quantity_by_variant.each do |variant, variant_quantity|
          unit_count = line_item.inventory_units
                                .where(variant: variant)
                                .reject(&:pending?)
                                .sum(&:quantity)

          next if unit_count >= variant_quantity

          quantity = variant_quantity - unit_count
          next if quantity.zero?

          # We actually want to check the whole order's variant.
          cart_quantity = variant_cart_quantity(line_item, variant, quantity)
          next if item_variant_available?(variant, cart_quantity)

          display_variant = if line_item.variant.product.assembly?
                              # If it's an assembly we want the bundle name
                              line_item.variant
                            else
                              # Otherwise we want the variant name
                              variant
                            end

          display_name = display_variant.name.to_s
          display_name += " (#{display_variant.options_text})" unless display_variant.options_text.blank?

          line_item.errors.add(:quantity,
                               :selected_quantity_not_available,
                               message: Spree.t(:selected_quantity_not_available,
                                                item: display_name.inspect))
        end
      end

      private

      def variant_cart_quantity(line_item, variant, quantity)
        Spree::Stock::CartEstimator.new(line_item, variant, quantity).run
      end

      # Don't override item_available? in case we want to look up by line item elsewhere
      def item_variant_available?(variant, quantity)
        Spree::Stock::Quantifier.new(variant).can_supply?(quantity)
      end
    end
  end
end
