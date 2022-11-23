# frozen_string_literal: true

require "concurrent/map"
require "concurrent/atomic/atomic_fixnum"
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
        registry[key].increment
      end

      # @api private
      def reset
        @registry = Concurrent::Map.new do |h, k|
          h.compute_if_absent(k) do
            Concurrent::AtomicFixnum.new(0)
          end
        end
        self
      end
    end
  end
end
