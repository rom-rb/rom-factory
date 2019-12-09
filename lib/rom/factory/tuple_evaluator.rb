# frozen_string_literal: true

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
      def defaults(traits, attrs, opts = EMPTY_HASH)
        evaluate(traits, attrs, opts).merge(attrs)
      end

      # @api private
      def struct(*traits, attrs)
        merged_attrs = struct_attrs.merge(defaults(traits, attrs, persist: false))
        is_callable = proc { |_name, value| value.respond_to?(:call) }

        callables = merged_attrs.select(&is_callable)
        attributes = merged_attrs.reject(&is_callable)

        materialized_callables = {}
        callables.each do |_name, callable|
          materialized_callables.merge!(callable.call(attributes, persist: false))
        end

        attributes.merge!(materialized_callables)

        associations = assoc_names
          .map { |key| [key, attributes[key]] if attributes.key?(key) }
          .compact
          .to_h

        attributes = relation.output_schema[attributes]
        attributes.update(associations)

        model.new(attributes)
      end

      # @api private
      def persist_associations(tuple, parent, traits = [])
        assoc_names(traits).each do |name|
          assoc = tuple[name]
          assoc.call(parent, persist: true) if assoc.is_a?(Proc)
        end
      end

      # @api private
      def assoc_names(traits = [])
        assocs(traits).map(&:name)
      end

      def assocs(traits_names = [])
        traits
          .values_at(*traits_names)
          .map(&:associations).flat_map(&:elements)
          .inject(AttributeRegistry.new(attributes.associations.elements), :<<)
      end

      # @api private
      def has_associations?(traits = [])
        !assoc_names(traits).empty?
      end

      # @api private
      def primary_key
        relation.primary_key
      end

      private

      # @api private
      def evaluate(traits, attrs, opts)
        evaluate_values(attrs, opts)
          .merge(evaluate_associations(attrs, opts))
          .merge(evaluate_traits(traits, attrs, opts))
      end

      # @api private
      def evaluate_values(attrs, opts)
        attributes.values.tsort.each_with_object({}) do |attr, h|
          deps = attr.dependency_names.map { |k| h[k] }.compact
          result = attr.(attrs, *deps)

          if result
            h.update(result)
          end
        end
      end

      def evaluate_traits(traits, attrs, opts)
        return {} if traits.empty?

        traits_attrs = self.traits.values_at(*traits).flat_map(&:elements)
        registry = AttributeRegistry.new(traits_attrs)
        self.class.new(registry, relation).defaults([], attrs, opts)
      end

      # @api private
      def evaluate_associations(attrs, opts)
        attributes.associations.each_with_object({}) do |assoc, h|
          if assoc.dependency?(relation)
            h[assoc.name] = ->(parent, call_opts) do
              assoc.call(parent, opts.merge(call_opts))
            end
          else
            result = assoc.(attrs, opts)
            h.update(result) if result
          end
        end
      end

      # @api private
      def struct_attrs
        struct_attrs = relation.schema.
          reject(&:primary_key?).
          map { |attr| [attr.name, nil] }.to_h

        if primary_key
          struct_attrs.merge(primary_key => next_id)
        else
          struct_attrs
        end
      end

      # @api private
      def next_id
        sequence.()
      end
    end
  end
end
