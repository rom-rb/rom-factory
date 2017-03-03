module ROM::Factory
  module Attributes
    class Callable
      attr_reader :dsl, :block

      def initialize(dsl, block)
        @dsl = dsl
        @block = block
      end

      def call
        dsl.instance_exec(&block)
      end
    end
  end
end
