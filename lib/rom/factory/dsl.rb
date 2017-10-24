require 'faker'
require 'dry/core/inflector'

require 'rom/factory/builder'
require 'rom/factory/attribute_registry'
require 'rom/factory/attributes/value'
require 'rom/factory/attributes/callable'
require 'rom/factory/attributes/sequence'
require 'rom/factory/attributes/association'

module ROM
  module Factory
    # @api private
    def self.fake(type, *args)
      api = Faker.const_get(Dry::Core::Inflector.classify(type.to_s))
      meth, *rest = args

      if meth.is_a?(Symbol)
        api.public_send(meth, *rest)
      else
        api.public_send(type, *args)
      end
    end

    # @api private
    class DSL < BasicObject
      define_method(:rand, ::Kernel.instance_method(:rand))

      attr_reader :_name, :_relation, :_attributes, :_factories, :_valid_names

      # @api private
      def initialize(name, attributes: AttributeRegistry.new, relation:, factories:)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_attributes = attributes.dup
        @_valid_names = _relation.schema.attributes.map(&:name)
        yield(self)
      end

      # @api private
      def call
        ::ROM::Factory::Builder.new(_attributes, _relation)
      end

      # @api private
      def create(name, *args)
        _factories[name, *args]
      end

      # @api private
      def sequence(meth, &block)
        if _valid_names.include?(meth)
          define_sequence(meth, block)
        end
      end

      # @api private
      def timestamps
        created_at { ::Time.now }
        updated_at { ::Time.now }
      end

      # @api private
      def fake(*args)
        ::ROM::Factory.fake(*args)
      end

      # @api private
      def association(name, options = {})
        assoc = _relation.associations[name]
        builder = -> { _factories.for_relation(assoc.target) }

        _attributes << attributes::Association.new(assoc, builder, options)
      end

      private

      # @api private
      def method_missing(meth, *args, &block)
        if _valid_names.include?(meth)
          define_attr(meth, *args, &block)
        else
          super
        end
      end

      # @api private
      def respond_to_missing?(method_name, include_private = false)
        _valid_names.include?(meth) || super
      end

      # @api private
      def define_sequence(name, block)
        _attributes << attributes::Callable.new(name, self, &attributes::Sequence.new(name, &block))
      end

      # @api private
      def define_attr(name, *args, &block)
        if block
          _attributes << attributes::Callable.new(name, self, &block)
        else
          _attributes << attributes::Value.new(name, *args)
        end
      end

      # @api private
      def attributes
        ::ROM::Factory::Attributes
      end
    end
  end
end
