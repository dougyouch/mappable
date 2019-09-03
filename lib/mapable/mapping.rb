# frozen_string_literal: true

module Mapable
  # Defines what fields to map
  module Mapping
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end
    
    def self.default_mapping_options(src, dest)
      {
        src: src.to_sym,
        src_getter: src.to_s.freeze,
        src_setter: "#{src}=",
        dest: dest.to_sym,
        dest_getter: dest.to_s.freeze,
        dest_setter: "#{dest}="
      }
    end

    # no-doc
    module ClassMethods
      def mappings
        {}.freeze
      end

      def map(src, dest = nil, options = {})
        if dest.is_a?(Hash)
          options = dest
          dest = nil
        end

        dest ||= src

        options = ::Mapable::Mapping.default_mapping_options(src, dest)
                                    .merge(options)

        add_value_to_class_method(:mappings, src.to_sym => options)
      end
    end

    def map(src_model, dest_model)
      self.class.mappings.each do |_, info|
        dest_model.public_send(info[:dest_setter], src_model.public_send(info[:src_getter]))
      end
      dest_model
    end

    def self.create(base_module, name, options = {}, &block)
      options[:class_name] ||= ::Mapable::Utils.classify_name(name.to_s) + 'Mapping'
      kls = Class.new(options[:base_class] || Object)
      kls = base_module.const_set(options[:class_name], kls)
      kls.send(:include, ::Mapable::Mapping)
      kls.class_eval(&block) if block
      kls
    end
  end
end
