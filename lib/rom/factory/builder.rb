require 'rom/factory/struct'

module ROM::Factory
  class Builder
    attr_reader :schema, :relation

    def initialize(schema, relation)
      @schema = schema
      @relation = relation
    end

    def create(attrs = {})
      tuple = schema.map {|k, v| [k, v.call] }.to_h.merge(attrs)
      pkval = relation.insert(tuple)

      Struct.new(tuple.merge(relation.primary_key => pkval))
    end
  end
end
