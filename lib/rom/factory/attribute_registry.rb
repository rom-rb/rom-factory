require 'tsort'

module ROM
  module Factory
    class AttributeRegistry
      include Enumerable
      include TSort

      attr_reader :elements

      def initialize(elements = [])
        @elements = elements
      end

      def each(&block)
        elements.each(&block)
      end

      def [](name)
        detect { |e| e.name.equal?(name) }
      end

      def <<(element)
        existing = self[element.name]
        elements.delete(existing) if existing
        elements << element
        self
      end

      def dup
        self.class.new(elements.dup)
      end

      def values
        self.class.new(elements.select(&:value?))
      end

      def associations
        self.class.new(elements.select { |e| e.kind_of?(Attributes::Association::Core) })
      end

      private

      def tsort_each_node(&block)
        each(&block)
      end

      def tsort_each_child(attr, &block)
        attr.dependency_names.map { |name| self[name] }.compact.each(&block)
      end
    end
  end
end
