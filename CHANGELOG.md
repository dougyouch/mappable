# Changelog

## [0.3.0](https://github.com/dougyouch/mappable/compare/v0.2.0...v0.3.0) (2026-10-05)


### ⚠ BREAKING CHANGES

* **gem:** Ruby 3.2 reached end of life in March 2026 and is no longer supported. CI now tests Ruby 3.3 and the .ruby-version Ruby, both with Gemfile.lock and the coverage gate.

### Build System

* **deps:** allow inheritance-helper 1.x and lock 1.0.0 ([69fdaf0](https://github.com/dougyouch/mappable/commit/69fdaf00519a7d9addbca706ebd440fe6f2a4561))
* **gem:** require ruby 3.3 ([f9d239f](https://github.com/dougyouch/mappable/commit/f9d239f782c0929e6f3d75471a928776f9d50b6d))

## [0.2.0](https://github.com/dougyouch/mappable/compare/v0.1.0...v0.2.0) (2026-10-05)


### ⚠ BREAKING CHANGES

* **mapping:** the internal Mapping instance methods map_data, skip?, get_value, call_method and call_map_method are removed.

### Features

* **mappable:** add map_from_&lt;name&gt; to copy data back from the destination ([2b1503f](https://github.com/dougyouch/mappable/commit/2b1503f5a619b77f1d2e342ecf06d5ff429c1392))


### Bug Fixes

* **mappable:** support map_to on anonymous classes and stop modifying options ([a5b3b7f](https://github.com/dougyouch/mappable/commit/a5b3b7f1ea0b2477f2213cd3e9c28fcdecda0934))
* **utils:** keep capital letters when building mapping class names ([5160516](https://github.com/dougyouch/mappable/commit/5160516a1d10bd9cf8593a34496bf95ee13a3330))


### Performance Improvements

* **mapping:** compile mappings into plain ruby methods ([8854abb](https://github.com/dougyouch/mappable/commit/8854abb763f976bbc76a4bd7cc00e9c1dde50908))
