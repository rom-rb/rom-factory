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
      define_methods_from_repos_schema
      yield(self)
    end

    attr_reader :_repo, :_name, :_as, :_schema

    private

    def define_methods_from_repos_schema
      _repo.root.relation.attributes.each do |a|
        define_singleton_method a, Proc.new {|v = nil, &block|
          if block
            _schema[a] = block
          else
            _schema[a] = v
          end
        }
      end
    end
  end
end
