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
      default_attrs(skip_key_names(attrs.keys)).merge(attrs)
    end

    def create(attrs = {})
      struct(attrs)
    end

    def struct(attrs)
      model.new(struct_attrs.merge(attrs))
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

    def default_attrs(skip = [])
      schema.map { |name, attr| [name, attr.()] unless skip.include?(name) }.compact.to_h
    end

    def struct_attrs
      relation.schema.
        reject(&:primary_key?).
        map { |attr| [attr.name, nil] }.
        to_h.
        merge(default_attrs).
        merge(primary_key => next_id)
    end

    def skip_key_names(keys)
      keys.map { |name| associations.key?(name) ? associations[name].foreign_key : name }
    end

    def associations
      relation.associations
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
