# frozen_string_literal: true

require "rom/factory/sequences"

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
      def defaults(traits, attrs, **opts)
        mergeable_attrs = select_mergeable_attrs(traits, attrs)
        evaluate(traits, attrs, opts).merge(mergeable_attrs)
      end

      # @api private
      def struct(*traits, **attrs)
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
          .map { |key|
            if (assoc = @attributes[key]) && assoc.count.positive?
              [key, build_assoc_attrs(key, attributes[relation.primary_key], attributes[key])]
            end
          }
          .compact
          .to_h

        attributes = relation.output_schema[attributes]
        attributes.update(associations)

        model.new(attributes)
      end

      def build_assoc_attrs(key, fk, value)
        if value.is_a?(Array)
          value.map { |el| build_assoc_attrs(key, fk, el) }
        else
          {attributes[key].foreign_key => fk}.merge(value.to_h)
        end
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
        found_assocs = traits
          .values_at(*traits_names)
          .compact
          .map(&:associations).flat_map(&:elements)
          .inject(AttributeRegistry.new(attributes.associations.elements), :<<)

        exclude = traits_names.select { |t| t.is_a?(Hash) }.reduce(:merge) || EMPTY_HASH

        found_assocs.reject { |a| exclude[a.name] == false }
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
        evaluate_values(attrs)
          .merge(evaluate_associations(traits, attrs, opts))
          .merge(evaluate_traits(traits, attrs, opts))
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

      def evaluate_traits(trait_list, attrs, opts)
        return {} if trait_list.empty?

        traits = trait_list.map { |v| v.is_a?(Hash) ? v : {v => true} }.reduce(:merge)

        traits_attrs = self.traits.select { |key, value| traits[key] }.values.flat_map(&:elements)
        registry = AttributeRegistry.new(traits_attrs)
        self.class.new(registry, relation).defaults([], attrs, **opts)
      end

      # @api private
      def evaluate_associations(traits, attrs, opts)
        assocs(traits).associations.each_with_object({}) do |assoc, h|
          if assoc.dependency?(relation)
            h[assoc.name] = ->(parent, call_opts) do
              assoc.call(parent, **opts, **call_opts)
            end
          else
            result = assoc.(attrs, **opts)
            h.update(result) if result
          end
        end
      end

      # @api private
      def struct_attrs
        struct_attrs = relation.schema
          .reject(&:primary_key?)
          .map { |attr| [attr.name, nil] }.to_h

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

      def select_mergeable_attrs(traits, attrs)
        unmergeable = assocs(traits).select(&:through?).map do |a|
          Dry::Core::Inflector.singularize(a.assoc.target.name.to_sym).to_sym
        end
        attrs.dup.delete_if { |key, _| unmergeable.include?(key) }
      end
    end
  end
end
