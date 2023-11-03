# frozen_string_literal: true

require "rom/struct"
require "rom/initializer"
require "rom/factory/tuple_evaluator"
require "rom/factory/builder/persistable"

module ROM::Factory
  # @api private
  class Builder
    extend ROM::Initializer

    include Dry::Core::Constants

    # @!attribute [r] attributes
    #   @return [ROM::Factory::Attributes]
    param :attributes

    # @!attribute [r] traits
    #   @return [Hash]
    param :traits, default: -> { EMPTY_HASH }

    # @!attribute [r] relation
    #   @return [ROM::Relation]
    option :relation, reader: false

    # @!attribute [r] struct_namespace
    #   @return [Module] Custom struct namespace
    option :struct_namespace, reader: false

    # @!attribute [r] factories
    #   @return [Module] Factories with other builders
    option :factories, reader: true, optional: true

    # @api private
    def tuple(*traits, **attrs)
      tuple_evaluator.defaults(traits, attrs)
    end

    # @api private
    def struct(*traits, **attrs)
      validate_keys(traits, attrs, allow_associations: true)

      tuple_evaluator.struct(*traits, **attrs)
    end
    alias_method :create, :struct

    # @api private
    def struct_namespace(namespace)
      if options[:struct_namespace][:overridable]
        with(struct_namespace: options[:struct_namespace].merge(namespace: namespace))
      else
        self
      end
    end

    # @api private
    def persistable
      Persistable.new(self, relation)
    end

    # @api private
    def tuple_evaluator
      @__tuple_evaluator__ ||= TupleEvaluator.new(attributes, tuple_evaluator_relation, traits)
    end

    # @api private
    def tuple_evaluator_relation
      options[:relation].struct_namespace(options[:struct_namespace][:namespace])
    end

    # @api private
    def relation
      tuple_evaluator.relation
    end

    # @api private
    def validate_keys(traits, tuple, allow_associations: false)
      schema_keys = relation.schema.attributes.map(&:name)
      assoc_keys = tuple_evaluator.assoc_names(traits)
      unknown_keys = tuple.keys - schema_keys - assoc_keys

      unknown_keys -= relation.schema.associations.to_h.keys if allow_associations

      raise UnknownFactoryAttributes, unknown_keys unless unknown_keys.empty?
    end
  end
end
