# frozen_string_literal: true

require 'inheritance-helper'

# Maps data from one object to another and back.
#
# Include it in a class and declare mappings with {ClassMethods#map_to}.
module Mappable
  autoload :ClassMethods, 'mappable/class_methods'
  autoload :Mapping, 'mappable/mapping'
  autoload :Utils, 'mappable/utils'
  autoload :VERSION, 'mappable/version'

  # @api private
  def self.included(base)
    base.extend InheritanceHelper::Methods
    base.extend ClassMethods
  end
end
