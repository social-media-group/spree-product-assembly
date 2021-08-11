module Spree
  module Stock
    # Overridden from spree core to make it also check for assembly parts stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        line_item.quantity_by_variant.each do |variant, variant_quantity|
          unit_count = line_item.inventory_units.where(variant: variant)
                                                .reject(&:pending?)
                                                .sum(&:quantity)

          return if unit_count >= variant_quantity

          quantity = variant_quantity - unit_count
          return if quantity.zero?

          return if item_variant_available?(variant, quantity)

          display_name = variant.name.to_s
          display_name += " (#{variant.options_text})" unless variant.options_text.blank?
          line_item.errors.add(:quantity,
                               :selected_quantity_not_available,
                               message: Spree.t(:selected_quantity_not_available, item: display_name.inspect))
        end
      end

      private

      # Don't override item_available? in case we want to look up by line item elsewhere
      def item_variant_available?(variant, quantity)
        Spree::Stock::Quantifier.new(variant).can_supply?(quantity)
      end
    end
  end
end
