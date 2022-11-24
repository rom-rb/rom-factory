# frozen_string_literal: true

require "concurrent/map"
require "singleton"

module ROM
  module Factory
    # @api private
    class Sequences
      include Singleton

      # @api private
      attr_reader :registry

      # @api private
      def self.[](relation)
        key = :"#{relation.gateway}-#{relation.name.dataset}"
        -> { instance.next(key) }
      end

      # @api private
      def initialize
        reset
      end

      # @api private
      def next(key)
        registry.compute(key) { |v| (v || 0).succ }
      end

      # @api private
      def reset
        @registry = Concurrent::Map.new
        self
      end
    end
  end
end
