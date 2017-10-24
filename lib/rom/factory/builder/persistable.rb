require 'delegate'

module ROM
  module Factory
    class Builder
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

          pk = persisted.values_at(*relation.schema.primary_key_names)

          if tuple_evaluator.has_associations?
            relation.by_pk(*pk).combine(*tuple_evaluator.assoc_names).first
          else
            relation.by_pk(*pk).first
          end
        end
      end
    end
  end
end
