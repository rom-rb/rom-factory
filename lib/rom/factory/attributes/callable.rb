# frozen_string_literal: true

module ROM::Factory
  module Attributes
    # @api private
    class Callable
      attr_reader :name, :dsl, :block, :transient

      # @api private
      def initialize(name, dsl, block, transient: false)
        @name = name
        @dsl = dsl
        @block = block
        @transient = transient
      end

      # @api private
      def call(attrs, *args)
        result = attrs[name] || dsl.instance_exec(*args, &block)
        {name => result}
      end

      # @api private
      def value?
        true
      end

      # @api private
      def dependency_names
        block.parameters.map(&:last)
      end

      # @api private
      def inspect
        "#<#{self.class.name} #{name} at #{block.source_location.join(":")}>"
      end
      alias_method :to_s, :inspect
    end
  end
end
