# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'model-mapper'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = 'Map data between models'
  s.description = 'Easy way to configure what data is mapped between models'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/mappable'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|script)/}) }

  s.add_runtime_dependency 'inheritance-helper'
end
