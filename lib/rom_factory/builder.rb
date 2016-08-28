module RomFactory
  class Builder
    @container = Dry::Container.new

    def self.container
      @container
    end

    def self.define(&block)
      factory = new(&block)
      raise ArgumentError, "Factory #{factory._name} already present" if container.key?(factory._name)
      container.register(factory._name, factory)
    end

    def self.create(name, attrs = {})
      factory = container.resolve(name)
      schema = factory._schema.merge(attrs)
      schema = schema.map do |k,v|
        if v.respond_to?(:call)
          [k, v.call]
        else
          [k, v]
        end
      end
      record = factory._repo.create(schema.to_h)
      factory._as ? factory._as.call(record.to_h) : record
    end

    def initialize
      yield(self)
    end

    def factory(name:, repo:, as: nil, &block)
      @_repo = repo.new(RomFactory::Config.config.container)
      @_name = name
      @_as = as
      @_schema = {}
      yield(self)
    end

    attr_reader :_repo, :_name, :_as, :_schema

    private

    def method_missing(name, *args, &block)
      if @_repo.root.relation.attributes.include?(name)
        if block_given?
          @_schema[name] = block
        else
          @_schema[name] = args.first
        end
      else
        raise NoMethodError, "undefined method `#{name}' for #{self}"
      end
    end
  end
end
