module ROM::Factory
  module Attributes
    # @api private
    class Callable
      attr_reader :name, :dsl, :block

      # @api private
      def initialize(name, dsl = nil, &block)
        @name = name
        @dsl = dsl
        @block = block
      end

      # @api private
      def call(attrs, *args)
        return if attrs.key?(name)
        result = dsl.instance_exec(*args, &block)
        { name => result }
      end

      # @api private
      def value?
        true
      end

      # @api private
      def dependency_names
        block.parameters.map(&:last)
      end
    end
  end
end
