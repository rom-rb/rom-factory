module ROM::Factory
  module Attributes
    class Callable
      attr_reader :name, :dsl, :block

      def initialize(name, dsl = nil, &block)
        @name = name
        @dsl = dsl
        @block = block
      end

      def call(attrs, *args)
        return if attrs.key?(name)

        result =
          if block.is_a?(Proc)
            dsl.instance_exec(*args, &block)
          else
            block.call
          end

        { name => result }
      end

      def dependency?(other)
        dependency_names.include?(other.name)
      end

      def dependency_names
        block.parameters.map(&:last)
      end
    end
  end
end
