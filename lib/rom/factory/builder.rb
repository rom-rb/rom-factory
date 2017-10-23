require 'delegate'

module ROM::Factory
  class Builder
    attr_reader :attributes, :relation, :model

    def initialize(attributes, relation)
      @attributes = attributes
      @relation = relation.with(auto_map: true, auto_struct: true)
      @model = @relation.combine(*assoc_names).mapper.model
      @sequence = 0
    end

    def assoc_names
      attributes.select { |attr| attr.is_a?(Attributes::Association::Core) }.map(&:name)
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
      attributes.tsort.each_with_object({}) do |attr, h|
        deps = attr.dependency_names.map { |k| h[k] }.compact
        result = attr.(attrs, *deps)

        if result
          h.update(result)
        end
      end
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
