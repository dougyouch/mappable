# frozen_string_literal: true

module Mappable
  # Class methods added by including {Mappable}
  module ClassMethods
    # @return [Hash{Symbol => Class}] mapping classes by name, as declared with {#map_to}
    def maps
      {}.freeze
    end

    # Creates a mapping class, a constant of this class, and two instance methods that use it:
    #
    # - `map_to_<name>(dest)` copies this object's fields to `dest` and returns `dest`
    # - `map_from_<name>(src)` copies the fields of `src` back to this object and returns `self`
    #
    # @example
    #   class User
    #     include Mappable
    #
    #     map_to(:contact) do
    #       map :email, :email_address
    #     end
    #   end
    #
    #   user.map_to_contact(Contact.new) # => the contact, with email_address set
    #   User.new.map_from_contact(contact) # => the user, with email set
    #
    # @param name [Symbol, String] names the methods and the mapping class (`:contact` creates `ContactMapping`)
    # @param options [Hash] see {Mapping.create}
    # @yield evaluated in the mapping class, to declare its mappings (see {Mapping::ClassMethods})
    # @return [Class] the mapping class
    def map_to(name, options = {}, &)
      mapping = Mapping.create(self, name, options, &)
      add_value_to_class_method(:maps, name.to_sym => mapping)
      # referenced by its constant name, resolved from this class, so anonymous classes work too
      mapping_const = mapping.name.split('::').last

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def map_to_#{name}(dest)                   # def map_to_contact(dest)
          #{mapping_const}.new.map(self, dest)     #   ContactMapping.new.map(self, dest)
        end                                        # end

        def map_from_#{name}(src)                  # def map_from_contact(src)
          #{mapping_const}.new.map_back(src, self) #   ContactMapping.new.map_back(src, self)
        end                                        # end
      RUBY

      mapping
    end
  end
end
