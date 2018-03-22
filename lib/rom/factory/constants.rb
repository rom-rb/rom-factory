module ROM
  module Factory
    class FactoryNotDefinedError < StandardError
      def initialize(name)
        super("Factory +#{name}+ not defined")
      end
    end

    class UnSupportedAssociationsError < StandardError
      def initialize
        super('In-memory structs do not support associations')
      end
    end
  end
end
