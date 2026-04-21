# frozen_string_literal: true

module ROM::Factory
  module Attributes
    # @api private
    class Value
      attr_reader :name, :value, :transient

      # @api private
      def initialize(name, value, transient: false)
        @name = name
        @value = value
        @transient = transient
      end

      # @api private
      def call(attrs = EMPTY_HASH)
        return if attrs.key?(name)

        {name => value}
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
