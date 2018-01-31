require 'dry/core/constants'

require 'rom/struct'
require 'rom/initializer'
require 'rom/factory/tuple_evaluator'
require 'rom/factory/builder/persistable'

module ROM::Factory
  # @api private
  class Builder
    extend ROM::Initializer

    include Dry::Core::Constants

    # @!attribute [r] attributes
    #   @return [ROM::Factory::Attributes]
    param :attributes

    # @!attribute [r] relation
    #   @return [ROM::Relation]
    option :relation, reader: false

    # @api private
    def tuple(attrs = EMPTY_HASH)
      tuple_evaluator.defaults(attrs)
    end

    # @api private
    def struct(attrs = EMPTY_HASH)
      tuple_evaluator.struct(attrs)
    end
    alias_method :create, :struct

    # @api private
    def struct_namespace(namespace)
      with(relation: relation.struct_namespace(namespace))
    end

    # @api private
    def persistable(struct_namespace = ROM::Struct)
      Persistable.new(self, relation.struct_namespace(struct_namespace))
    end

    # @api private
    def tuple_evaluator
      @__tuple_evaluator__ ||= TupleEvaluator.new(attributes, options[:relation])
    end

    # @api private
    def relation
      tuple_evaluator.relation
    end
  end
end
