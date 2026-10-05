# frozen_string_literal: true

module Mappable
  # General purpose utility methods
  module Utils
    module_function

    # Converts a mapping name into a class name: drops anything that isn't a letter,
    # digit, underscore or dash, then camel cases the words split by underscores and dashes.
    #
    # @example
    #   Mappable::Utils.classify_name('user_profile') # => "UserProfile"
    #   Mappable::Utils.classify_name('UserProfile')  # => "UserProfile"
    #
    # @param name [String, Symbol]
    # @return [String]
    def classify_name(name)
      name.to_s.gsub(/[^\da-zA-Z_-]/, '').gsub(/(?:\A|[_-]+)([\da-zA-Z])/) { ::Regexp.last_match(1).upcase }
    end
  end
end
