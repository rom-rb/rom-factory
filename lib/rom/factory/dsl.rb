# frozen_string_literal: true

require "faker"

require "rom/factory/builder"
require "rom/factory/attribute_registry"
require "rom/factory/attributes"

module ROM
  module Factory
    extend ::Dry::Core::Cache

    class << self
      # @api private
      def fake(*args, unique: false, **options)
        factory, produce = fetch_or_store(:faker, unique, *args) do
          *ns, method_name = args

          const = ns.reduce(::Faker) do |obj, name|
            obj.const_get(::ROM::Inflector.camelize(name))
          end

          if unique
            [const.unique, method_name]
          else
            [const, method_name]
          end
        end

        factory.public_send(produce, **options)
      end
    end

    # Factory builder DSL
    #
    # @api public
    class DSL < ::BasicObject
      # @api private
      module Kernel
        %i[binding class instance_of? is_a? rand respond_to_missing? singleton_class].each do |meth|
          define_method(meth, ::Kernel.instance_method(meth))
        end

        private :respond_to_missing?, :rand, :binding
      end

      include Kernel

      attr_reader :_name, :_relation, :_attributes, :_factories, :_struct_namespace, :_valid_names
      attr_reader :_traits

      # @api private
      def initialize(name, relation:, factories:, struct_namespace:, attributes: AttributeRegistry.new)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_struct_namespace = struct_namespace
        @_attributes = attributes.dup
        @_traits = {}
        @_valid_names = _relation.schema.attributes.map(&:name)
        yield(self)
      end

      # @api private
      def call
        ::ROM::Factory::Builder.new(
          _attributes,
          _traits,
          relation: _relation,
          struct_namespace: _struct_namespace,
          factories: _factories
        )
      end

      # Delegate to a builder and persist a struct
      #
      # @param [Symbol] The name of the registered builder
      #
      # @api public
      def create(name, *args) = _factories[name, *args]

      # Create a sequence attribute
      #
      # @param [Symbol] name The attribute name
      #
      # @api private
      def sequence(meth, &)
        define_sequence(meth, &) if _valid_names.include?(meth)
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
      # @overload fake(genre, type)
      #   @example
      #     f.email { fake(:internet, :email) }
      #
      #   @param [Symbol] genre The faker API identifier ie. :internet, :product etc.
      #   @param [Symbol] type The value type to generate
      #
      # @overload fake(genre, type, **options)
      #   @example
      #     f.email { fake(:number, :between, from: 10, to: 100) }
      #
      #   @example
      #    f.email { fake(:internet, :email, unique: true) }
      #
      #   @param [Symbol] genre The faker API identifier ie. :internet, :product etc.
      #   @param [Symbol] type The value type to generate
      #   @param [Hash] options Additional arguments, including unique: true will generate unique values
      #
      #
      # @overload fake(genre, subgenre, type, **options)
      #   @example
      #     f.quote { fake(:books, :dune, :quote, character: 'stilgar') }
      #
      #   @param [Symbol] genre The Faker genre of API i.e. :books, :creature, :games etc
      #   @param [Symbol] subgenre The subgenre of API i.e. :dune, :bird, :myst etc
      #   @param [Symbol] type the value type to generate
      #   @param [Hash] options Additional arguments
      #
      # @see https://github.com/faker-ruby/faker/tree/master/doc
      #
      # @api public
      def fake(...) = ::ROM::Factory.fake(...)

      def trait(name, parents = [], &)
        _traits[name] = DSL.new(
          "#{_name}_#{name}",
          attributes: _traits.values_at(*parents).flat_map(&:elements).inject(
            AttributeRegistry.new, :<<
          ),
          relation: _relation,
          factories: _factories,
          struct_namespace: _struct_namespace,
          &
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
      # @example adding traits
      #   f.association(:posts, traits: [:published])
      #
      # @param [Symbol] name The name of the configured association
      # @param [Hash] options Additional options
      # @option options [Integer] count Number of objects to generate
      # @option options [Array<Symbol>] traits Traits to apply to the association
      #
      # @api public
      def association(name, *seq_traits, traits: EMPTY_ARRAY, **options)
        assoc = _relation.associations[name]

        if assoc.is_a?(::ROM::SQL::Associations::OneToOne) && options.fetch(:count, 1) > 1
          ::Kernel.raise ::ArgumentError, "count cannot be greater than 1 on a OneToOne"
        end

        builder = -> { _factories.for_relation(assoc.target) }

        _attributes << attributes::Association.new(
          assoc,
          builder,
          *seq_traits,
          *traits,
          **options
        )
      end

      # @api private
      def inspect = "#<#{self.class} name=#{_name}>"
      alias_method :to_s, :inspect

      private

      # @api private
      def method_missing(meth, ...)
        if _valid_names.include?(meth)
          define_attr(meth, ...)
        else
          super
        end
      end

      # @api private
      def respond_to_missing?(method_name, include_private = false)
        _valid_names.include?(method_name) || super
      end

      # @api private
      def define_sequence(name, &)
        _attributes << attributes::Callable.new(name, self, attributes::Sequence.new(name, &))
      end

      # @api private
      def define_attr(name, *args, &block)
        _attributes <<
          if block
            attributes::Callable.new(name, self, block)
          else
            attributes::Value.new(name, *args)
          end
      end

      # @api private
      def attributes = ::ROM::Factory::Attributes
    end
  end
end
