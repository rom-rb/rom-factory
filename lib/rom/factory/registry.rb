module ROM
  module Factory
    class Registry < Hash
      def [](name)
        raise NotDefinedFactory.new(name) unless include?(name)

        super
      end
    end
  end
end
