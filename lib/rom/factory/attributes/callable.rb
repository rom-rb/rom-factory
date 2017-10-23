module ROM::Factory
  module Attributes
    class Callable
      attr_reader :name, :dsl, :block

      def initialize(name, dsl, block)
        @name = name
        @dsl = dsl
        @block = block
      end

      def call(attrs)
        return if attrs.key?(name)

        result =
          if block.is_a?(Proc)
            dsl.instance_exec(&block)
          else
            block.call
          end

        { name => result }
      end
    end
  end
end
