module ROM::Factory
  module Attributes
    class Callable
      attr_reader :dsl, :block

      def initialize(dsl, block)
        @dsl = dsl
        @block = block
      end

      def call
        if block.is_a?(Proc)
          dsl.instance_exec(&block)
        else
          block.call
        end
      end
    end
  end
end
