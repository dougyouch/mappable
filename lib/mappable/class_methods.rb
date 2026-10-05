# frozen_string_literal: true

module Mappable
  # Class methods added by including {Mappable}
  module ClassMethods
    # @return [Hash{Symbol => Class}] mapping classes by name, as declared with {#map_to}
    def maps
      {}.freeze
    end

    def map_to(name, options = {}, &block)
      mapping = Mapping.create(self, name, options, &block)
      add_value_to_class_method(:maps, name.to_sym => mapping)
      # referenced by its constant name, resolved from this class, so anonymous classes work too
      mapping_const = mapping.name.split('::').last

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def map_to_#{name}(dest)                   # def map_to_contact(dest)
          #{mapping_const}.new.map(self, dest)     #   ContactMapping.new.map(self, dest)
        end                                        # end
      RUBY

      mapping
    end
  end
end
