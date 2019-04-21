# frozen_string_literal: true

module ROM
  module Factory
    class FactoryNotDefinedError < StandardError
      def initialize(name)
        super("Factory +#{name}+ not defined")
      end
    end
  end
end
