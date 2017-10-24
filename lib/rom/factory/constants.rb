module ROM
  module Factory

    class NotDefinedFactory < StandardError
      def initialize(name)
        super("Factory +#{name}+ not defined")
      end
    end

  end
end
