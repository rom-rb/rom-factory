require 'delegate'

module ROM::Factory
  class Builder
    attr_reader :schema, :relation, :model

    def initialize(schema, relation)
      @schema = schema
      @relation = relation.with(auto_map: true, auto_struct: true)
      @model = @relation.combine(*assoc_names).mapper.model
      @sequence = 0
    end

    def assoc_names
      schema.keys.select { |key| schema[key].is_a?(Attributes::Association) }
    end

    def tuple(attrs)
      default_attrs(attrs).merge(attrs)
    end

    def create(attrs = {})
      struct(attrs)
    end

    def struct(attrs)
      model.new(struct_attrs.merge(tuple(attrs)))
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

    def default_attrs(attrs)
      schema.values.map { |attr| attr.(attrs) }.compact.reduce(:merge)
    end

    def struct_attrs
      relation.schema.
        reject(&:primary_key?).
        map { |attr| [attr.name, nil] }.
        to_h.
        merge(primary_key => next_id)
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
