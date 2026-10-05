# Architecture

This document describes the internal architecture of the `model-mapper` gem (module `Mappable`).

## Overview

A mapping class declares which fields are copied from one object to another. Every declaration regenerates two plain Ruby methods on the mapping class, so running a mapping does no option lookups:

```
map / custom_map / custom_map_back
        ↓
mappings + map_back_mappings (class-level hashes)
        ↓
Compiler → source of map(src, dest) and map_back(src, dest) → class_eval
        ↓
dest.x = src.y if ...   (one line per field)
```

## Files

```
lib/model-mapper.rb                   entry point (gem name), requires mappable
lib/mappable.rb                       Mappable: autoloads, included hook
lib/mappable/class_methods.rb         Mappable::ClassMethods: map_to, maps
lib/mappable/mapping.rb               Mappable::Mapping: create, option builders, default map/map_back
lib/mappable/mapping/class_methods.rb Mappable::Mapping::ClassMethods: the DSL, compile_mappings
lib/mappable/compiler.rb              Mappable::Compiler: mapping options -> method source
lib/mappable/utils.rb                 Mappable::Utils: classify_name
lib/mappable/version.rb               Mappable::VERSION (bumped by release-please)
```

## Core Components

### Mappable (`lib/mappable.rb`, `lib/mappable/class_methods.rb`)

Included into the object being mapped from. `map_to(name, options, &block)`:

1. Calls `Mapping.create(self, name, options, &block)`, which sets a new class (`<Name>Mapping`, or `options[:class_name]`) as a constant of the including class, with `options[:base_class]` as its superclass.
2. Records it in `maps` (keyed by symbol).
3. `class_eval`s `map_to_<name>(dest)` and `map_from_<name>(src)`. They refer to the mapping class by its constant name, resolved lexically from the including class, rather than by its full name, which isn't valid Ruby for anonymous classes (`Struct.new(...) { include Mappable }`).

### Mappable::Mapping (`lib/mappable/mapping.rb`)

- **Option builders**: `default_mapping_options(src, dest)` (`src`, `getter`, `dest`, `setter`), `default_custom_mapping_options(dest, method)` (`map_method`, `dest`, `setter`), and `map_back_options`, which reverses a `map` call using `MAP_BACK_CONDITIONS` (`if`/`unless` stay, `_src` and `_dest` conditions swap).
- **Default `map` / `map_back`**: return the destination untouched. A class with mappings replaces them with generated methods.

### Mappable::Mapping::ClassMethods (`lib/mappable/mapping/class_methods.rb`)

- `mappings` / `map_back_mappings`: frozen hashes keyed by the field being written. Stored with `inheritance-helper`'s `add_value_to_class_method`, which redefines the class method with a merged copy, so a subclass snapshots its parent's mappings when it declares its first one.
- `map` adds to both hashes; `custom_map` adds to `mappings`; `custom_map_back` adds to `map_back_mappings`.
- `compile_mappings` runs after every declaration: it builds both methods with one `Compiler`, stores the compiler's procs in the private `MAPPABLE_PROCS` constant on the class (replacing any previous one), removes the class's own `map`/`map_back`, and `class_eval`s the new source.

### Mappable::Compiler (`lib/mappable/compiler.rb`)

Turns a mappings hash into a method `name(src_model, dest_model)` that returns `dest_model`. Each field becomes one line:

- **Value**: `src_model.getter`, `self.method(src_model)` for a custom method (so it can be private), or `MAPPABLE_PROCS[i].call(src_model)` for a block.
- **Assignment**: `dest_model.field = value`.
- **Conditions**: checked in the order `if`, `unless`, `if_dest`, `unless_dest`, `if_src`, `unless_src`, joined with `&&` into a trailing `if`. Symbols and strings become method calls on the receiver (`self`, `dest_model` or `src_model`); procs become `receiver.instance_exec(receiver, &MAPPABLE_PROCS[i])`, without the argument for lambdas that take none.
- **Odd names**: names that can't be called with dot syntax (`:'first-name'`) are called with `public_send` (`__send__` on `self`), with the name written as a symbol literal via `Symbol#inspect`, so no user input is written into the source unescaped.
- Invalid conditions or custom methods raise `ArgumentError` when declared.

`map_back` is generated with the same signature: its first argument is the object read from (the original destination). That's why the reverse options swap `_src` and `_dest`.

## Inheritance

- A mapping created with `base_class:` (or any subclass of a mapping class) inherits the parent's generated methods and, through lexical constant lookup, the parent's `MAPPABLE_PROCS`. Once it declares a mapping, it gets its own methods and constant built from the merged mappings; the parent is unchanged.
- Subclasses of a class that includes `Mappable` inherit its `map_to_*` / `map_from_*` methods and `maps`.

## Dependencies

- `inheritance-helper`: class-level values that subclasses inherit and override.
