# frozen_string_literal: true

module Mappable
  # Turns mapping options into the source of a Ruby method, so running a mapping is a
  # series of plain method calls instead of hash lookups and +public_send+.
  #
  # @example
  #   # map :email, :email_address, if_dest: :persisted?
  #   # custom_map(:name) { |user| "#{user.first_name} #{user.last_name}" }
  #   #
  #   # compiles to
  #   def map(src_model, dest_model)
  #     dest_model.email_address = src_model.email if dest_model.persisted?
  #     dest_model.name = MAPPABLE_PROCS[0].call(src_model)
  #     dest_model
  #   end
  #
  # Procs can't be written into source, so they are collected in {#procs} and the
  # generated code reads them from the {PROCS_CONSTANT} constant on the mapping class.
  # Names that can't be called with dot syntax are called with +public_send+.
  #
  # @api private
  class Compiler
    # Name of the constant on the mapping class that holds {#procs}
    PROCS_CONSTANT = :MAPPABLE_PROCS

    # A method name that can be called with dot syntax
    METHOD_NAME = /\A[a-zA-Z_]\w*[?!]?\z/

    # A setter name that can be called with assignment syntax
    SETTER_NAME = /\A[a-zA-Z_]\w*=\z/

    # Condition options in the order they are checked: option, receiver, negated
    CONDITIONS = [
      [:if, 'self', false],
      [:unless, 'self', true],
      [:if_dest, 'dest_model', false],
      [:unless_dest, 'dest_model', true],
      [:if_src, 'src_model', false],
      [:unless_src, 'src_model', true]
    ].freeze

    # @return [Array<Proc>] the procs referenced by the generated source, by index
    attr_reader :procs

    def initialize
      @procs = []
    end

    # @param method_name [Symbol] name of the generated method
    # @param mappings [Hash{Symbol => Hash}] mapping options, as built by {Mapping::ClassMethods}
    # @return [String] source of a method that takes (src_model, dest_model) and returns dest_model
    # @raise [ArgumentError] when a condition or map method is not a Symbol, String or Proc
    def method_source(method_name, mappings)
      lines = mappings.each_value.map { |options| "  #{assignment(options)}" }
      ["def #{method_name}(src_model, dest_model)", *lines, '  dest_model', 'end'].join("\n")
    end

    private

    def assignment(options)
      line = setter_call(options[:setter].to_s, value(options))
      condition = condition(options)
      condition ? "#{line} if #{condition}" : line
    end

    def value(options)
      return method_call('src_model', options[:getter].to_s) unless options[:map_method]

      map_method_call(options[:map_method])
    end

    def map_method_call(map_method)
      case map_method
      when Symbol, String
        method_call('self', map_method.to_s, 'src_model')
      when Proc
        "#{proc_ref(map_method)}.call(src_model)"
      else
        raise ArgumentError, "map method must be a Symbol, String or Proc, got #{map_method.inspect}"
      end
    end

    def condition(options)
      checks = CONDITIONS.filter_map do |option, receiver, negated|
        next unless options[option]

        check = condition_call(receiver, options[option])
        negated ? "!(#{check})" : check
      end
      checks.join(' && ') unless checks.empty?
    end

    # Proc conditions run with the receiver as self and get it as their argument;
    # lambdas that take no arguments are called without it
    def condition_call(receiver, condition)
      case condition
      when Symbol, String
        method_call(receiver, condition.to_s)
      when Proc
        arg = condition.lambda? && condition.arity.zero? ? '' : "#{receiver}, "
        "#{receiver}.instance_exec(#{arg}&#{proc_ref(condition)})"
      else
        raise ArgumentError, "condition must be a Symbol, String or Proc, got #{condition.inspect}"
      end
    end

    # self.name(...) can call the mapping's private methods; other receivers only public ones
    def method_call(receiver, name, *args)
      call_args = args.empty? ? '' : "(#{args.join(', ')})"
      return "#{receiver}.#{name}#{call_args}" if METHOD_NAME.match?(name)

      send_method = receiver == 'self' ? '__send__' : 'public_send'
      "#{receiver}.#{send_method}(#{[name.to_sym.inspect, *args].join(', ')})"
    end

    def setter_call(setter, value)
      return "dest_model.#{setter.delete_suffix('=')} = #{value}" if SETTER_NAME.match?(setter)

      "dest_model.public_send(#{setter.to_sym.inspect}, #{value})"
    end

    def proc_ref(proc)
      @procs << proc
      "#{PROCS_CONSTANT}[#{@procs.size - 1}]"
    end
  end
end
