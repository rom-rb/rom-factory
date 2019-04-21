# frozen_string_literal: true

require 'singleton'

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
        registry[key] += 1
      end

      # @api private
      def reset
        @registry = Concurrent::Map.new { |h, k| h[k] = 0 }
        self
      end
    end
  end
end
