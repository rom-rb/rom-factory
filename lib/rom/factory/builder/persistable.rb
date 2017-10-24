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
          tuple = tuple(attrs)
          persisted = persist(tuple)

          if tuple_evaluator.has_associations?
            tuple_evaluator.persist_associations(tuple, persisted)

            pk = primary_key_names.map { |key| persisted[key] }

            relation.by_pk(*pk).combine(*tuple_evaluator.assoc_names).first
          else
            persisted
          end
        end

        private

        def persist(attrs)
          relation.with(auto_struct: !tuple_evaluator.has_associations?).command(:create).call(attrs)
        end

        def primary_key_names
          relation.schema.primary_key_names
        end
      end
    end
  end
end
