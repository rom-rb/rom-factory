# frozen_string_literal: true

module ROM::Factory
  module Attributes
    class Sequence
      attr_reader :name, :count, :block, :transient

      def initialize(name, transient: false, &block)
        @name = name
        @count = 0
        @transient = transient
        @block = block
      end

      def call(*args)
        block.call(increment, *args)
      end

      def to_proc
        method(:call).to_proc
      end

      def increment
        @count += 1
      end

      def dependency_names
        EMPTY_ARRAY
      end

      def parameters
        block.parameters
      end
    end
  end
end
