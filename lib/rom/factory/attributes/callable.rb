module ROM::Factory
  module Attributes
    class Callable
      def initialize(block)
        @block = block
      end

      def call
        @block.call
      end
    end
  end
end
