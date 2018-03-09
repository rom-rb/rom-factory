require 'rom/factory/sequences'

module ROM
  module Factory
    # @api private
    class TupleEvaluator
      # @api private
      attr_reader :attributes

      # @api private
      attr_reader :relation

      # @api private
      attr_reader :traits

      # @api private
      attr_reader :model

      # @api private
      attr_reader :sequence

      # @api private
      def initialize(attributes, relation, traits = {})
        @attributes = attributes
        @relation = relation.with(auto_struct: true)
        @traits = traits
        @model = @relation.combine(*assoc_names).mapper.model
        @sequence = Sequences[relation]
      end

      # @api private
      def defaults(*traits, **attrs)
        evaluate(*traits, attrs).merge(attrs)
      end

      # @api private
      def struct(*traits, attrs)
        model.new(struct_attrs.merge(defaults(*traits, attrs)))
      end

      # @api private
      def persist_associations(tuple, parent)
        assoc_names.each do |name|
          assoc = tuple[name]
          assoc.(parent) if assoc.is_a?(Proc)
        end
      end

      # @api private
      def assoc_names
        attributes.associations.map(&:name)
      end

      # @api private
      def has_associations?
        assoc_names.size > 0
      end

      # @api private
      def primary_key
        relation.primary_key
      end

      private

      # @api private
      def evaluate(*traits, **attrs)
        evaluate_values(attrs)
          .merge(evaluate_associations(attrs))
          .merge(evaluate_traits(*traits, **attrs))
      end

      # @api private
      def evaluate_values(attrs)
        attributes.values.tsort.each_with_object({}) do |attr, h|
          deps = attr.dependency_names.map { |k| h[k] }.compact
          result = attr.(attrs, *deps)

          if result
            h.update(result)
          end
        end
      end

      def evaluate_traits(*traits, **attrs)
        return {} if traits.empty?

        traits_attrs = self.traits.slice(*traits).values.flat_map(&:elements)
        registry = AttributeRegistry.new(traits_attrs)
        self.class.new(registry, relation).defaults(**attrs)
      end

      # @api private
      def evaluate_associations(attrs)
        attributes.associations.each_with_object({}) do |assoc, h|
          if assoc.dependency?(relation)
            h[assoc.name] = -> parent { assoc.call(parent) }
          else
            result = assoc.(attrs)
            h.update(result) if result
          end
        end
      end

      # @api private
      def struct_attrs
        relation.schema.
          reject(&:primary_key?).
          map { |attr| [attr.name, nil] }.
          to_h.
          merge(primary_key => next_id)
      end

      # @api private
      def next_id
        sequence.()
      end
    end
  end
end
