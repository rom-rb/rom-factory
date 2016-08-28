module RomFactory
  class Builder
    @container = Dry::Container.new

    def self.container
      @container
    end

    def self.define(&block)
      factory = new(&block)
      raise ArgumentError, "Factory #{factory.name} already present" if container.key?(factory.name)
      container.register(factory.name, factory)
    end

    def self.create(name, attrs = {})
      raise ArgumentError, "Factory #{name} does not exist" unless container.key?(name)
      factory = container.resolve(name)
      factory.create(attrs)
    end

    def initialize
      yield(self)
    end

    def factory(name:, repo:, as: nil, &block)
      @_repo = repo.new(RomFactory::Config.config.container)
      @name = name
      @_as = as
      @_schema = {}
      define_methods_from_repos_schema
      yield(self)
    end

    def create(attrs)
      schema = _schema.merge(attrs).map do |k, v|
        if v.respond_to?(:call)
          [k, v.call]
        else
          [k, v]
        end
      end
      record = _repo.create(schema.to_h)
      _as ? _as.call(record.to_h) : record
    end

    attr_reader :name

    private

    attr_reader :_repo, :_as, :_schema

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
