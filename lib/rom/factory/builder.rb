require 'delegate'
require 'rom/factory/struct'

module ROM::Factory
  class Builder
    attr_reader :schema, :relation

    def initialize(schema, relation)
      @schema = schema
      @relation = relation
      @sequence = 0
    end

    def tuple(attrs)
      schema.map {|k, v| [k, v.call] }.to_h.merge(attrs)
    end

    def create(attrs = {})
      struct(tuple(attrs.merge(primary_key => next_id)))
    end

    def struct(attrs)
      Struct.define(relation.name, relation.schema.project(*attrs.keys)).new(attrs)
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
  end

  class Persistable < SimpleDelegator
    attr_reader :builder, :relation

    def initialize(builder, relation = builder.relation)
      super(builder)
      @builder = builder
      @relation = relation
    end

    def create(attrs = {})
      tuple = builder.tuple(attrs)
      struct(tuple.merge(primary_key => relation.insert(tuple)))
    end
  end
end
