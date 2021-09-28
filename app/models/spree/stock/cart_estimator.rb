module Spree
  module Stock
    # Need to estimate how much of a variant is in the cart.
    class CartEstimator
      attr_reader :order, :variant

      def initialize(line_item, variant, quantity)
        @line_item = line_item
        @order = line_item.order
        @variant = variant
        @quantity = quantity
      end

      def run
        quantities = [@quantity]

        # Get quantity from the order item itself first.
        quantities << @order.line_items.where(variant_id: @variant.id)
                            .where.not(id: @line_item.id)
                            .sum(&:quantity)

        # If this variant is a part of something, check it.
        if variant.part?
          quantities << Spree::PartLineItem.joins(:line_item)
                                           .where(spree_line_items: { order_id: @order.id },
                                                  variant_id: @variant.id)
                                           .where.not(spree_line_items: { id: @line_item.id })
                                           .sum(&:quantity)
        end

        quantities.compact.sum
      end
    end
  end
end
