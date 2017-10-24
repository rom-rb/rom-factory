require 'dry/core/constants'

require 'rom/factory/tuple_evaluator'
require 'rom/factory/builder/persistable'

module ROM::Factory
  # @api private
  class Builder
    include Dry::Core::Constants

    # @api private
    attr_reader :attributes

    # @api private
    attr_reader :tuple_evaluator

    # @api private
    def initialize(attributes, relation)
      @attributes = attributes
      @tuple_evaluator = TupleEvaluator.new(attributes, relation)
    end

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
    def persistable
      Persistable.new(self)
    end

    # @api private
    def relation
      tuple_evaluator.relation
    end
  end
end
