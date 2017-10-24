require 'rom/factory/tuple_evaluator'
require 'rom/factory/builder/persistable'

module ROM::Factory
  class Builder
    attr_reader :attributes

    attr_reader :tuple_evaluator

    def initialize(attributes, relation)
      @attributes = attributes
      @tuple_evaluator = TupleEvaluator.new(attributes, relation)
    end

    def tuple(attrs = {})
      tuple_evaluator.defaults(attrs)
    end

    def struct(attrs = {})
      tuple_evaluator.struct(attrs)
    end
    alias_method :create, :struct

    def persistable
      Persistable.new(self)
    end

    def relation
      tuple_evaluator.relation
    end
  end
end
