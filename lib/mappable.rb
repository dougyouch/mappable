# frozen_string_literal: true

require 'inheritance-helper'

# Transfer/Map data from one model to the next
module Mappable
  autoload :Mapping, 'mappable/mapping'
  autoload :Utils, 'mappable/utils'

  def self.included(base)
    base.extend InheritanceHelper::Methods
    base.extend ClassMethods
  end

  # no-doc
  module ClassMethods
    def maps
      {}.freeze
    end

    def map_to(name, options = {}, &block)
      mapping = Mapping.create(self, name, options, &block)
      add_value_to_class_method(:maps, name => mapping)

      class_eval(
<<-STR, __FILE__, __LINE__ + 1
  def map_to_#{name}(dest)
    ::#{mapping.name}.new.map(self, dest)
    dest
  end
STR
      )
    end
  end
end
