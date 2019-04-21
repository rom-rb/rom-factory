# frozen_string_literal: true

require 'tsort'

module ROM
  module Factory
    # @api private
    class AttributeRegistry
      include Enumerable
      include TSort

      # @api private
      attr_reader :elements

      # @api private
      def initialize(elements = [])
        @elements = elements
      end

      # @api private
      def each(&block)
        elements.each(&block)
      end

      # @api private
      def [](name)
        detect { |e| e.name.equal?(name) }
      end

      # @api private
      def <<(element)
        existing = self[element.name]
        elements.delete(existing) if existing
        elements << element
        self
      end

      # @api private
      def dup
        self.class.new(elements.dup)
      end

      # @api private
      def values
        self.class.new(elements.select(&:value?))
      end

      # @api private
      def associations
        self.class.new(elements.select { |e| e.kind_of?(Attributes::Association::Core) })
      end

      private

      # @api private
      def tsort_each_node(&block)
        each(&block)
      end

      # @api private
      def tsort_each_child(attr, &block)
        attr.dependency_names.map { |name| self[name] }.compact.each(&block)
      end
    end
  end
end
