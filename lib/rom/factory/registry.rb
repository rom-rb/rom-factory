# frozen_string_literal: true

require 'rom/factory/constants'

module ROM
  module Factory
    # @api private
    class Registry
      # @!attribute [r] elements
      #   @return [Hash] a hash with factory builders
      attr_reader :elements

      # @api private
      def initialize
        @elements = {}
      end

      # @api private
      def key?(name)
        elements.key?(name)
      end

      # @api private
      def []=(name, builder)
        elements[name] = builder
      end

      # @api private
      def [](name)
        elements.fetch(name) do
          raise FactoryNotDefinedError.new(name)
        end
      end
    end
  end
end
