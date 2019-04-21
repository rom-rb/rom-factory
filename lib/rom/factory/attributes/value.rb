# frozen_string_literal: true

module ROM::Factory
  module Attributes
    # @api private
    class Value
      attr_reader :name, :value

      # @api private
      def initialize(name, value)
        @name = name
        @value = value
      end

      # @api private
      def call(attrs = EMPTY_HASH)
        return if attrs.key?(name)

        { name => value }
      end

      # @api private
      def value?
        true
      end

      # @api private
      def dependency_names
        EMPTY_ARRAY
      end
    end
  end
end
