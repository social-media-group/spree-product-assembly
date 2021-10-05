module Spree::VariantDecorator
  def self.prepended(base)
    base.has_many :parts_variants, class_name: 'Spree::AssembliesPart', foreign_key: 'assembly_id'
    base.has_many :assemblies_variants, class_name: 'Spree::AssembliesPart', foreign_key: 'part_id'

    base.has_many :assemblies, through: :assemblies_variants, class_name: 'Spree::Variant', dependent: :destroy
    base.has_many :parts, through: :parts_variants, class_name: 'Spree::Variant', dependent: :destroy
  end

  def assemblies_for(products)
    assemblies.where(id: products)
  end

  def part?
    assemblies.exists?
  end

  def in_stock?
    if parts.present?
      parts_variants.all?(&:in_stock?) && super
    else
      super
    end
  end
end

Spree::Variant.prepend Spree::VariantDecorator
