# frozen_string_literal: true

require_relative 'lib/mappable/version'

Gem::Specification.new do |s|
  s.name        = 'model-mapper'
  s.version     = Mappable::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Fast, declarative two-way mapping between Ruby objects'
  s.description = 'Declare once how fields map from one object to another, and Mappable compiles it into plain Ruby ' \
                  'methods that copy the data both ways at close to hand-written speed. Rename fields, combine ' \
                  'several into one (first_name + last_name -> name) and split them back out, and skip fields ' \
                  'with conditions on the source, the destination or the mapping itself. Works with any objects ' \
                  'that have getters and setters: Structs, ActiveRecord models, plain Ruby classes.'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/mappable'
  s.files       = Dir['lib/**/*.rb', 'README.md', 'LICENSE', 'CHANGELOG.md']
  s.required_ruby_version = '>= 3.3'

  s.add_dependency 'inheritance-helper', '~> 0.2'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['source_code_uri'] = 'https://github.com/dougyouch/mappable'
  s.metadata['changelog_uri'] = 'https://github.com/dougyouch/mappable/blob/master/CHANGELOG.md'
  s.metadata['bug_tracker_uri'] = 'https://github.com/dougyouch/mappable/issues'
  s.metadata['documentation_uri'] = 'https://rubydoc.info/gems/model-mapper'
end
