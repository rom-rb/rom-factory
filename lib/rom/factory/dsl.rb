# frozen_string_literal: true

require 'faker'
require 'dry/core/inflector'

require 'rom/factory/builder'
require 'rom/factory/attribute_registry'
require 'rom/factory/attributes'

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

    # Factory builder DSL
    #
    # @api public
    class DSL < BasicObject
      define_method(:rand, ::Kernel.instance_method(:rand))

      attr_reader :_name, :_relation, :_attributes, :_factories, :_valid_names
      attr_reader :_traits

      # @api private
      def initialize(name, attributes: AttributeRegistry.new, relation:, factories:)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_attributes = attributes.dup
        @_traits = {}
        @_valid_names = _relation.schema.attributes.map(&:name)
        yield(self)
      end

      # @api private
      def call
        ::ROM::Factory::Builder.new(_attributes, _traits, relation: _relation)
      end

      # Delegate to a builder and persist a struct
      #
      # @param [Symbol] The name of the registered builder
      #
      # @api public
      def create(name, *args)
        _factories[name, *args]
      end

      # Create a sequence attribute
      #
      # @param [Symbol] name The attribute name
      #
      # @api private
      def sequence(meth, &block)
        define_sequence(meth, block) if _valid_names.include?(meth)
      end

      # Set timestamp attributes
      #
      # @api public
      def timestamps
        created_at { ::Time.now }
        updated_at { ::Time.now }
      end

      # Create a fake value using Faker gem
      #
      # @overload fake(type)
      #   @example
      #     f.email { fake(:name) }
      #
      #   @param [Symbol] type The value type to generate
      #
      # @overload fake(api, type)
      #   @example
      #     f.email { fake(:internet, :email) }
      #
      #   @param [Symbol] api The faker API identifier ie. :internet, :product etc.
      #   @param [Symbol] type The value type to generate
      #
      # @overload fake(api, type, *args)
      #   @example
      #     f.email { fake(:number, :between, 10, 100) }
      #
      #   @param [Symbol] api The faker API identifier ie. :internet, :product etc.
      #   @param [Symbol] type The value type to generate
      #   @param [Array] args Additional arguments
      #
      # @see https://github.com/stympy/faker/tree/master/doc
      #
      # @api public
      def fake(*args)
        ::ROM::Factory.fake(*args)
      end

      def trait(name, parents = [], &block)
        _traits[name] = DSL.new(
          "#{_name}_#{name}",
          attributes: _traits.values_at(*parents).flat_map(&:elements).inject(
            AttributeRegistry.new, :<<
          ),
          relation: _relation,
          factories: _factories,
          &block
        )._attributes
      end

      # Create an association attribute
      #
      # @example belongs-to
      #   f.association(:group)
      #
      # @example has-many
      #   f.association(:posts, count: 2)
      #
      # @param [Symbol] name The name of the configured association
      # @param [Hash] options Additional options
      # @option options [Integer] count Number of objects to generate (has-many only)
      #
      # @api public
      def association(name, *traits, **options)
        assoc = _relation.associations[name]
        builder = -> { _factories.for_relation(assoc.target) }

        _attributes << attributes::Association.new(assoc, builder, *traits, **options)
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
        _attributes << attributes::Callable.new(name, self, attributes::Sequence.new(name, &block))
      end

      # @api private
      def define_attr(name, *args, &block)
        _attributes << if block
                         attributes::Callable.new(name, self, block)
                       else
                         attributes::Value.new(name, *args)
                       end
      end

      # @api private
      def attributes
        ::ROM::Factory::Attributes
      end
    end
  end
end
