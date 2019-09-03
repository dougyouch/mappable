# frozen_string_literal: true

module Mappable
  # General purpouse utility methods
  module Utils
    module_function

    def classify_name(name)
      name.gsub(/[^\da-z_-]/, '').gsub(/(^.|[_|-].)/) { |m| m[-1].upcase }
    end
  end
end
