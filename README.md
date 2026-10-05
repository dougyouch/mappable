# Mappable

Fast, declarative two-way mapping between Ruby objects. Declare once how the fields of one object map to another, and Mappable compiles it into plain Ruby methods that copy the data in either direction at close to hand-written speed.

[![CI](https://github.com/dougyouch/mappable/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/dougyouch/mappable/actions/workflows/ci.yml)
[![Coverage](https://raw.githubusercontent.com/dougyouch/mappable/badges/coverage.svg)](https://github.com/dougyouch/mappable/actions/workflows/ci.yml)
[![Branch Coverage](https://raw.githubusercontent.com/dougyouch/mappable/badges/branches.svg)](https://github.com/dougyouch/mappable/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/model-mapper.svg)](https://rubygems.org/gems/model-mapper)

[API reference](https://rubydoc.info/gems/model-mapper) · [Changelog](CHANGELOG.md) · [Architecture](ARCHITECTURE.md)

## Installation

Requires Ruby 3.2 or newer. The gem is published as `model-mapper`:

```ruby
gem 'model-mapper'
```

```ruby
require 'model-mapper' # Bundler does this for you
```

## Quick Start

Map a `User` to a `Contact`, combining `first_name` and `last_name` into `name`, and split `name` back out on the way back:

```ruby
User = Struct.new(:first_name, :last_name, :email)
Contact = Struct.new(:name, :email_address)

class User
  include Mappable

  map_to(:contact) do
    # user -> contact
    custom_map(:name) { |user| "#{user.first_name} #{user.last_name}" }

    # contact -> user
    custom_map_back(:first_name) { |contact| contact.name.split(' ', 2).first }
    custom_map_back(:last_name) { |contact| contact.name.split(' ', 2).last }

    # both directions: email -> email_address and email_address -> email
    map :email, :email_address
  end
end

user = User.new('Ada', 'Lovelace', 'ada@example.com')

contact = user.map_to_contact(Contact.new)
contact.name          # => "Ada Lovelace"
contact.email_address # => "ada@example.com"

copy = User.new.map_from_contact(contact)
copy.first_name # => "Ada"
copy.last_name  # => "Lovelace"
copy.email      # => "ada@example.com"
```

`map_to(:contact)` creates a mapping class, `User::ContactMapping`, and two instance methods:

| Method | Does | Returns |
|---|---|---|
| `map_to_contact(dest)` | copies the user's fields to `dest` | `dest` |
| `map_from_contact(src)` | copies the fields of `src` back to the user | the user |

Any objects work as long as they have getters for the fields being read and setters (`name=`) for the fields being written: Structs, plain Ruby classes, ActiveRecord or ActiveModel models.

## Declaring Mappings

### `map`: copy a field, both ways

```ruby
map :email                  # email -> email,         and back
map :email, :email_address  # email -> email_address, and email_address -> email
```

### `custom_map`: compute a field

`custom_map` sets a destination field from a block, or from a method on the mapping class. It's one-way; declare the reverse with `custom_map_back`.

```ruby
map_to(:contact) do
  custom_map(:name) { |user| "#{user.first_name} #{user.last_name}" }

  custom_map :initials                 # calls initials(user)
  custom_map :display_name, :full_name # calls full_name(user)

  def initials(user)
    "#{user.first_name[0]}#{user.last_name[0]}"
  end

  private

  def full_name(user) # custom methods can be private
    [user.first_name, user.last_name].compact.join(' ')
  end
end
```

### `custom_map_back`: compute a field on the way back

`custom_map_back` sets a field on the source object from the destination object. It takes the same arguments as `custom_map`.

```ruby
custom_map_back(:first_name) { |contact| contact.name.split(' ', 2).first }
custom_map_back :last_name # calls last_name(contact)
```

## Conditions

Skip a field unless a condition holds. Every mapping method takes these options:

| Option | Checked on |
|---|---|
| `if:` / `unless:` | the mapping instance |
| `if_src:` / `unless_src:` | the object being read from |
| `if_dest:` / `unless_dest:` | the object being written to |

A condition is a method name, called on that object, or a proc, run with that object as `self` and passed as its argument. A lambda that takes no arguments works too.

```ruby
map_to(:contact) do
  map :email, :email_address, if_src: :email_verified?
  map :phone, unless_dest: :phone_locked?
  map :notes, if: -> { include_notes }
  map :status, unless_src: ->(user) { user.status.nil? }

  attr_accessor :include_notes
end
```

Each `map` call also declares the reverse mapping, and the reverse swaps `_src` and `_dest` conditions so they still check the same object. In the example above, `if_src: :email_verified?` checks the user in both directions: on the way to the contact the user is the source, and on the way back it's the destination.

When a field has several conditions, all of them must pass.

## Using Mapping Classes Directly

The mapping class is a regular class you can instantiate, which is how you pass it state such as the `include_notes` flag above:

```ruby
mapping = User::ContactMapping.new
mapping.include_notes = true
mapping.map(user, Contact.new)     # => the contact
mapping.map_back(contact, User.new) # => the user
```

You can also define mapping classes without `map_to`:

```ruby
class ContactMapping
  include Mappable::Mapping

  map :email, :email_address
end

ContactMapping.new.map(user, Contact.new)
```

### `map_to` options

```ruby
# name the mapping class (defaults to ContactMapping, set as a constant of the including class)
map_to(:contact, class_name: 'PersonMapper') { ... }

# inherit mappings from another mapping class and add to them
map_to(:admin_contact, base_class: User::ContactMapping) do
  map :role
end
```

A subclass gets the mappings its base class had when the subclass declared its first mapping. Declare a base class's mappings before you subclass it.

### Inspecting mappings

`mappings` and `map_back_mappings` return the options for each field. Any extra options you pass, such as a description, are kept:

```ruby
map :email, :email_address, description: 'primary email'

User::ContactMapping.mappings[:email_address]
# => {src: :email, getter: "email", dest: :email_address, setter: "email_address=", description: "primary email"}

User.maps # => {contact: User::ContactMapping}
```

## Performance

Mappable doesn't interpret the mapping hash at runtime. Each `map`, `custom_map` or `custom_map_back` call regenerates the mapping class's `map` and `map_back` methods as straight-line Ruby, so mapping an object is a list of getter and setter calls:

```ruby
map :email, :email_address, if_dest: :persisted?
custom_map(:name) { |user| "#{user.first_name} #{user.last_name}" }

# compiles to
def map(src_model, dest_model)
  dest_model.email_address = src_model.email if dest_model.persisted?
  dest_model.name = MAPPABLE_PROCS[0].call(src_model)
  dest_model
end
```

Mapping 9 fields between Structs (one computed field, one condition), on Ruby 4.0.7 without YJIT:

| | ns per object |
|---|---|
| hand-written assignments | 490 |
| `map_to_contact` (this version) | 636 |
| `map_to_contact` (model-mapper 0.1.0) | 4560 |

Recompiling happens when mappings are declared, so declare them when your classes load, not per request.

## Development

```bash
bundle install
bundle exec rspec    # tests, with line and branch coverage in coverage/
bundle exec rubocop  # lint
bundle exec yard     # API docs in doc/
```

CI runs RuboCop, requires every public API to have YARD docs, and runs the specs on Ruby 3.2 and on the Ruby in `.ruby-version`, where it requires 100% line and branch coverage.

Releases are automated with [release-please](https://github.com/googleapis/release-please): [conventional commits](https://www.conventionalcommits.org/) on `master` keep a release PR up to date, and merging it tags the release and publishes the gem to RubyGems.

## License

MIT. See [LICENSE](LICENSE).
