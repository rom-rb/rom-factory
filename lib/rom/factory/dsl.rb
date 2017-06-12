require 'faker'
require 'dry/core/inflector'

require 'rom/factory/builder'
require 'rom/factory/attributes/regular'
require 'rom/factory/attributes/callable'
require 'rom/factory/attributes/sequence'

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

      attr_reader :_name, :_relation, :_schema, :_factories, :_valid_names

      def initialize(name, schema: {}, relation:, factories:, &block)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_schema = schema.dup
        @_valid_names = _relation.schema.attributes.map(&:name)
        yield(self)
      end

      def call
        ::ROM::Factory::Builder.new(_schema, _relation)
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

      def association(name)
        assoc = _relation.associations[name]
        other = assoc.target

        fk = _relation.foreign_key(other)
        pk = other.primary_key

        block = -> { create(name)[pk] }

        _schema[fk] = attributes::Callable.new(self, block)
      end

      private

      def method_missing(meth, *args, &block)
        if _valid_names.include?(meth)
          define_attr(meth, *args, &block)
        else
          super
        end
      end

      def define_sequence(name, block)
        _schema[name] = attributes::Callable.new(self, attributes::Sequence.new(&block))
      end

      def define_attr(name, *args, &block)
        if block
          _schema[name] = attributes::Callable.new(self, block)
        else
          _schema[name] = attributes::Regular.new(*args)
        end
      end

      def attributes
        ::ROM::Factory::Attributes
      end
    end
  end
end
