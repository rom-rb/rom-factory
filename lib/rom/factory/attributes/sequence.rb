module ROM::Factory
  module Attributes
    class Sequence
      attr_reader :name, :count, :block

      def initialize(name, &block)
        @name = name
        @count = 0
        @block = block
      end

      def call(attrs = EMPTY_HASH)
        return if attrs.key?(name)
        block.call(increment)
      end

      def to_proc
        method(:call).to_proc
      end

      def increment
        @count += 1
      end

      def dependency_names
        EMPTY_ARRAY
      end
    end
  end
end
