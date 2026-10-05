# frozen_string_literal: true

module Mappable
  module Mapping
    # The mapping DSL, added to classes that include {Mapping}.
    #
    # ## Conditions
    #
    # {#map}, {#custom_map} and {#custom_map_back} take conditions that skip the field
    # when they don't hold:
    #
    # - `:if` / `:unless` - checked on the mapping instance
    # - `:if_src` / `:unless_src` - checked on the object being read from
    # - `:if_dest` / `:unless_dest` - checked on the object being written to
    #
    # A condition is a method name, called on that object, or a proc, run with the
    # object as `self` and passed as its argument (a lambda may take no arguments).
    # For {#map}, the reverse mapping swaps the `_src` and `_dest` conditions so they
    # still check the same object.
    module ClassMethods
      # @return [Hash{Symbol => Hash}] options for each field {Mapping#map} sets, by field name
      def mappings
        {}.freeze
      end

      # @return [Hash{Symbol => Hash}] options for each field {Mapping#map_back} sets, by field name
      def map_back_mappings
        {}.freeze
      end

      # Copies the `src` field to the `dest` field, and `dest` back to `src` in {Mapping#map_back}.
      #
      # @example
      #   map :email                  # email -> email
      #   map :email, :email_address  # email -> email_address
      #   map :active, if_dest: :new_record?
      #
      # @param src [Symbol, String] field read from the source
      # @param dest [Symbol, String] field written on the destination, defaults to `src`
      # @param options [Hash] conditions (see {ClassMethods}); other keys are kept in {#mappings}
      # @return [void]
      def map(src, dest = nil, options = {})
        if dest.is_a?(Hash)
          options = dest
          dest = nil
        end

        dest ||= src

        options = ::Mappable::Mapping.default_mapping_options(src, dest).merge(options)
        add_value_to_class_method(:mappings, dest.to_sym => options)
        add_value_to_class_method(:map_back_mappings, src.to_sym => ::Mappable::Mapping.map_back_options(options))
        compile_mappings
      end

      # Sets the `dest` field from a method of the mapping, or a block, given the source.
      # Only applies to {Mapping#map}; use {#custom_map_back} for the reverse.
      #
      # @example
      #   custom_map :name                  # calls the mapping's name(src) method
      #   custom_map :name, :full_name      # calls full_name(src)
      #   custom_map(:name) { |src| "#{src.first_name} #{src.last_name}" }
      #
      # @param dest [Symbol, String] field written on the destination
      # @param custom_method [Symbol, String, Proc] defaults to the block, then to `dest`
      # @param options [Hash] conditions (see {ClassMethods}); other keys are kept in {#mappings}
      # @return [void]
      def custom_map(dest, custom_method = nil, options = {}, &)
        add_custom_mapping(:mappings, dest, custom_method, options, &)
      end

      # Sets the `dest` field on the source object from a method of the mapping, or a block,
      # given the destination object. Used by {Mapping#map_back}.
      #
      # @example
      #   custom_map_back(:first_name) { |contact| contact.name.split(' ', 2).first }
      #
      # @param dest [Symbol, String] field written on the source object
      # @param custom_method [Symbol, String, Proc] defaults to the block, then to `dest`
      # @param options [Hash] conditions (see {ClassMethods}); other keys are kept in {#map_back_mappings}
      # @return [void]
      def custom_map_back(dest, custom_method = nil, options = {}, &)
        add_custom_mapping(:map_back_mappings, dest, custom_method, options, &)
      end

      # Regenerates {Mapping#map} and {Mapping#map_back} from the current mappings.
      # @api private
      # @return [void]
      def compile_mappings
        compiler = ::Mappable::Compiler.new
        source = [
          compiler.method_source(:map, mappings),
          compiler.method_source(:map_back, map_back_mappings)
        ].join("\n")

        store_procs(compiler.procs)
        %i[map map_back].each { |name| remove_method(name) if method_defined?(name, false) }
        class_eval(source, __FILE__, __LINE__)
      end

      private

      def add_custom_mapping(method, dest, custom_method, options, &block)
        if custom_method.is_a?(Hash)
          options = custom_method
          custom_method = nil
        end

        custom_method ||= block || dest

        options = ::Mappable::Mapping.default_custom_mapping_options(dest, custom_method).merge(options)
        add_value_to_class_method(method, dest.to_sym => options)
        compile_mappings
      end

      def store_procs(procs)
        name = ::Mappable::Compiler::PROCS_CONSTANT
        remove_const(name) if const_defined?(name, false)
        const_set(name, procs.freeze)
        private_constant(name)
      end
    end
  end
end
