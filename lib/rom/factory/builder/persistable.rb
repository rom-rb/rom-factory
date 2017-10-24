require 'delegate'

module ROM
  module Factory
    class Builder
      # @api private
      class Persistable < SimpleDelegator
        # @api private
        attr_reader :builder

        # @api private
        attr_reader :relation

        # @api private
        def initialize(builder, relation = builder.relation)
          super(builder)
          @builder = builder
          @relation = relation
        end

        # @api private
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

        # @api private
        def persist(attrs)
          relation.with(auto_struct: !tuple_evaluator.has_associations?).command(:create).call(attrs)
        end

        # @api private
        def primary_key_names
          relation.schema.primary_key.map(&:name)
        end
      end
    end
  end
end
