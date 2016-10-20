module RomFactory
  class Builder
    @container = Dry::Container.new

    def self.container
      @container
    end

    def self.define(&block)
      factory = Factory.new(&block)
      raise ArgumentError, "Factory with key #{factory._name} already present" if container.key?(factory._name)
      container.register(factory._name, factory)
    end

    def self.create(name, attrs = {})
      raise ArgumentError, "Factory #{name} does not exist" unless container.key?(name)
      factory = container.resolve(name)
      factory.create(attrs)
    end
  end
end
