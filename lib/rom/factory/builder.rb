require 'delegate'

module ROM::Factory
  class Builder
    attr_reader :schema, :relation, :model

    def initialize(schema, relation)
      @schema = schema
      @relation = relation.with(auto_map: true, auto_struct: true)
      @model = @relation.mapper.model
      @sequence = 0
    end

    def tuple(attrs)
      default_attrs.merge(attrs)
    end

    def create(attrs = {})
      struct(tuple(attrs.merge(primary_key => next_id)))
    end

    def struct(attrs)
      model.new(tuple(attrs))
    end

    def persistable
      Persistable.new(self)
    end

    def primary_key
      relation.primary_key
    end

    private

    def next_id
      @sequence += 1
    end

    def default_attrs
      schema.map { |name, attr| [name, attr.()] }.to_h
    end
  end

  class Persistable < SimpleDelegator
    attr_reader :builder, :relation

    def initialize(builder, relation = builder.relation)
      super(builder)
      @builder = builder
      @relation = relation
    end

    def create(attrs = {})
      relation.command(:create).call(tuple(attrs))
    end
  end
end
