# frozen_string_literal: true

require "tsort"

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
      def each(&) = elements.each(&)

      # @api private
      def [](name) = detect { |e| e.name.equal?(name) }

      # @api private
      def <<(element)
        existing = self[element.name]
        elements.delete(existing) if existing
        elements << element
        self
      end

      # @api private
      def dup = self.class.new(elements.dup)

      # @api private
      def values = self.class.new(elements.select(&:value?))

      # @api private
      def associations
        self.class.new(elements.select { |e| e.is_a?(Attributes::Association::Core) })
      end

      def reject(&) = self.class.new(elements.reject(&))

      # @api private
      def inspect
        "#<#{self.class} #{elements.inspect}>"
      end
      alias_method :to_s, :inspect

      private

      # @api private
      def tsort_each_node(&) = each(&)

      # @api private
      def tsort_each_child(attr, &)
        attr.dependency_names.map { |name| self[name] }.compact.each(&)
      end
    end
  end
end
