require 'faker'
require 'dry/core/inflector'

require 'rom/factory/builder'
require 'rom/factory/attribute_registry'
require 'rom/factory/attributes/regular'
require 'rom/factory/attributes/callable'
require 'rom/factory/attributes/sequence'
require 'rom/factory/attributes/association'

module ROM
  module Factory
    def self.fake(type, *args)
      api = Faker.const_get(Dry::Core::Inflector.classify(type.to_s))
      meth, *rest = args

      if meth.is_a?(Symbol)
        api.public_send(meth, *rest)
      else
        api.public_send(type, *args)
      end
    end

    class DSL < BasicObject
      define_method(:rand, ::Kernel.instance_method(:rand))

      attr_reader :_name, :_relation, :_attributes, :_factories, :_valid_names

      def initialize(name, attributes: AttributeRegistry.new, relation:, factories:, &block)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_attributes = attributes.dup
        @_valid_names = _relation.schema.attributes.map(&:name)
        yield(self)
      end

      def call
        ::ROM::Factory::Builder.new(_attributes, _relation)
      end

      def create(name, *args)
        _factories[name, *args]
      end

      def sequence(meth, &block)
        if _valid_names.include?(meth)
          define_sequence(meth, block)
        end
      end

      def timestamps
        created_at { ::Time.now }
        updated_at { ::Time.now }
      end

      def fake(*args)
        ::ROM::Factory.fake(*args)
      end

      def association(name, options = {})
        assoc = _relation.associations[name]
        builder = -> { _factories.for_relation(assoc.target) }

        _attributes << attributes::Association.new(assoc, builder, options)
      end

      private

      def method_missing(meth, *args, &block)
        if _valid_names.include?(meth)
          define_attr(meth, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        _valid_names.include?(meth) || super
      end

      def define_sequence(name, block)
        _attributes << attributes::Callable.new(name, self, &attributes::Sequence.new(name, &block))
      end

      def define_attr(name, *args, &block)
        if block
          _attributes << attributes::Callable.new(name, self, &block)
        else
          _attributes << attributes::Regular.new(name, *args)
        end
      end

      def attributes
        ::ROM::Factory::Attributes
      end
    end
  end
end
