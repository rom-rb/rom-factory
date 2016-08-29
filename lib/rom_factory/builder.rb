module RomFactory
  class Builder
    @container = Dry::Container.new

    def self.container
      @container
    end

    def self.define(&block)
      factory = new(&block)
      raise ArgumentError, "Factory with key #{factory.name} already present" if container.key?(factory.name)
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

    def factory(name:, relation:, &block)
      @_relation = RomFactory::Config.config.container.relations.fetch(relation)
      @name = name
      @_schema = {}
      define_methods_from_relation
      yield(self)
    end

    def create(attrs)
      values = _schema.merge(attrs).map do |k, v|
        if v.respond_to?(:call)
          [k, v.call]
        else
          [k, v]
        end
      end
      record_id = _relation.insert(values.to_h)
      OpenStruct.new(_relation.where(id: record_id).one)
    end

    attr_reader :name

    private

    attr_reader :_relation, :_schema

    def define_methods_from_relation
      _relation.attributes.each do |a|
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
