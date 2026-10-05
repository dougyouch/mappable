# frozen_string_literal: true

module Mappable
  # Declares which fields are copied from one object to another, and back.
  #
  # Mapping classes are usually created by {Mappable::ClassMethods#map_to}, but any
  # class can include this module and declare mappings with {ClassMethods#map},
  # {ClassMethods#custom_map} and {ClassMethods#custom_map_back}. Each declaration
  # regenerates the class's {#map} and {#map_back} methods (see {Compiler}).
  #
  # @example
  #   class ContactMapping
  #     include Mappable::Mapping
  #
  #     map :email, :email_address
  #     custom_map(:name) { |user| "#{user.first_name} #{user.last_name}" }
  #     custom_map_back(:first_name) { |contact| contact.name.split(' ', 2).first }
  #     custom_map_back(:last_name) { |contact| contact.name.split(' ', 2).last }
  #   end
  #
  #   ContactMapping.new.map(user, Contact.new)      # => the contact
  #   ContactMapping.new.map_back(contact, User.new) # => the user
  module Mapping
    autoload :ClassMethods, 'mappable/mapping/class_methods'

    # @api private
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end

    # Options for copying the `src` field into the `dest` field
    # @api private
    def self.default_mapping_options(src, dest)
      {
        src: src.to_sym,
        getter: src.to_s.freeze,
        dest: dest.to_sym,
        setter: "#{dest}="
      }
    end

    # Options for setting the `dest` field from a custom method or proc
    # @api private
    def self.default_custom_mapping_options(dest, custom_method)
      {
        map_method: custom_method,
        dest: dest.to_sym,
        setter: "#{dest}="
      }
    end

    # Each condition of a {ClassMethods#map} call and the condition it becomes in the
    # reverse mapping. The source and destination swap places, so _src and _dest
    # conditions swap too and still check the same object.
    # @api private
    MAP_BACK_CONDITIONS = {
      if: :if,
      unless: :unless,
      if_src: :if_dest,
      unless_src: :unless_dest,
      if_dest: :if_src,
      unless_dest: :unless_src
    }.freeze

    # Reverses the options of a {ClassMethods#map} call (see {MAP_BACK_CONDITIONS})
    # @api private
    def self.map_back_options(options)
      new_options = default_mapping_options(options[:dest], options[:src])
      MAP_BACK_CONDITIONS.each do |cond, map_back_cond|
        new_options[map_back_cond] = options[cond] if options[cond]
      end
      new_options
    end

    # Creates a mapping class and sets it as a constant of `base_module`.
    #
    # @param base_module [Module] where the class's constant is set
    # @param name [String, Symbol] the class is named after it: `:contact` becomes `ContactMapping`
    # @param options [Hash]
    # @option options [String] :class_name the class's name instead of one built from `name`
    # @option options [Class] :base_class superclass, so a mapping can extend another one
    # @yield evaluated in the class, to declare its mappings
    # @return [Class]
    def self.create(base_module, name, options = {}, &block)
      class_name = options[:class_name] || "#{::Mappable::Utils.classify_name(name)}Mapping"
      kls = base_module.const_set(class_name, Class.new(options[:base_class] || Object))
      kls.include(::Mappable::Mapping)
      kls.class_eval(&block) if block
      kls
    end

    # Copies the mapped fields from `src_model` to `dest_model`. Replaced by a generated
    # method once the class declares a mapping.
    #
    # @param _src_model [Object] not read: there is nothing to copy
    # @param dest_model [Object]
    # @return [Object] dest_model
    def map(_src_model, dest_model)
      dest_model
    end

    # Copies the fields of `dest_model` back to `src_model`, reversing {#map}. Replaced by a
    # generated method once the class declares a mapping.
    #
    # @param _dest_model [Object] the object to read from, not read: there is nothing to copy
    # @param src_model [Object] the object to write to
    # @return [Object] src_model
    def map_back(_dest_model, src_model)
      src_model
    end
  end
end
