# frozen_string_literal: true

module Mappable
  # Defines what fields to map
  module Mapping
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end

    def self.default_mapping_options(src, dest)
      {
        src: src.to_sym,
        getter: src.to_s.freeze,
        dest: dest.to_sym,
        setter: "#{dest}="
      }
    end

    def self.default_custom_mapping_options(dest, custom_method)
      {
        map_method: custom_method,
        dest: dest.to_sym,
        setter: "#{dest}="
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

        options = ::Mappable::Mapping.default_mapping_options(src, dest)
                                     .merge(options)

        add_value_to_class_method(:mappings, dest.to_sym => options)
      end

      def custom_map(dest, custom_method = nil, options = {})
        if custom_method.is_a?(Hash)
          options = custom_method
          custom_method = nil
        end

        custom_method ||= dest

        options = ::Mappable::Mapping.default_custom_mapping_options(dest, custom_method)
                                     .merge(options)

        add_value_to_class_method(:mappings, dest.to_sym => options)
      end
    end

    def map(src_model, dest_model)
      map_data(src_model, dest_model, self.class.mappings)
    end

    def map_data(src_model, dest_model, mappings)
      self.class.mappings.each do |_, options|
        next if skip?(src_model, dest_model, options)

        dest_model.public_send(options[:setter], get_value(src_model, options))
      end
      dest_model
    end

    # TODO: fix me
    def map_back(src_model, dest_model)
    end

    def skip?(src_model, dest_model, options)
      return true if options[:if] && !call_method(self, options[:if])
      return true if options[:unless] && call_method(self, options[:unless])
      return true if options[:if_dest] && !call_method(dest_model, options[:if_dest])
      return true if options[:unless_dest] && call_method(dest_model, options[:unless_dest])
      return true if options[:if_src] && !call_method(src_model, options[:if_src])
      return true if options[:unless_src] && call_method(src_model, options[:unless_src])

      false
    end

    def call_method(model, method)
      case method
      when Symbol
        model.public_send(method)
      when Proc
        model.instance_eval(&method)
      else
        raise("wrong type, failed to call method #{method}")
      end
    end

    def call_map_method(model, method)
      case method
      when Symbol
        public_send(method, model)
      when Proc
        instance_eval(&method)
      else
        raise("wrong type, failed to call method #{method}")
      end
    end

    def get_value(model, options)
      if options[:map_method]
        call_map_method(model, options[:map_method])
      else
        model.public_send(options[:getter])
      end
    end

    def self.create(base_module, name, options = {}, &block)
      options[:class_name] ||= ::Mappable::Utils.classify_name(name.to_s) + 'Mapping'
      kls = Class.new(options[:base_class] || Object)
      kls = base_module.const_set(options[:class_name], kls)
      kls.send(:include, ::Mappable::Mapping)
      kls.class_eval(&block) if block
      kls
    end
  end
end
