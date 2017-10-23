require 'delegate'

module ROM::Factory
  class Builder
    attr_reader :attributes, :relation, :model

    def initialize(attributes, relation)
      @attributes = attributes
      @relation = relation.with(auto_struct: true)
      @model = @relation.combine(*assoc_names).mapper.model
      @sequence = 0
    end

    def assoc_names
      attributes.associations.map(&:name)
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
      defaults = attributes.values.tsort.each_with_object({}) do |attr, h|
        deps = attr.dependency_names.map { |k| h[k] }.compact
        result = attr.(attrs, *deps)

        if result
          h.update(result)
        end
      end

      attributes.associations.each_with_object(defaults) do |assoc, h|
        if assoc.dependency?(relation)
          h[assoc.name] = -> struct { assoc.call(attrs, struct) }
        else
          h.update(assoc.(attrs))
        end
      end

      defaults
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
      tuple_attrs = tuple(attrs)
      persisted = relation.with(auto_struct: false).command(:create).call(tuple_attrs)

      tuple_attrs.each do |name, attr|
        if attr.is_a?(Proc)
          attr.(persisted)
        end
      end

      pk = persisted[relation.primary_key]

      if assoc_names.any?
        relation.by_pk(pk).combine(*assoc_names).one
      else
        relation.by_pk(pk).one
      end
    end
  end
end
