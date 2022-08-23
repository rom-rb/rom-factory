# frozen_string_literal: true

module ROM
  module Factory
    class FactoryNotDefinedError < StandardError
      def initialize(name)
        super("Factory +#{name}+ not defined")
      end
    end

    class UnknownFactoryAttributes < StandardError
      def initialize(attrs)
        super("Unknown attributes: #{attrs.join(", ")}")
      end
    end
  end
end
