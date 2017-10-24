require 'dry/configurable'
require 'dry/core/inflector'

require 'rom/factory/dsl'

module ROM::Factory
  # In-memory builder API
  #
  # @api public
  class Structs
    # @!attribute [r] registry
    #   @return [Hash<Symbol=>Builder>]
    attr_reader :registry

    # @api private
    def initialize(registry)
      @registry = registry
    end

    # Build an in-memory struct
    #
    # @example create a struct with default attributes
    #   MyFactory[:user]
    #
    # @example create a struct with some attributes overridden
    #   MyFactory.structs[:user, name: "Jane"]
    #
    # @param [Symbol] name The name of the registered factory
    # @param [Hash] attrs An optional hash with attributes
    #
    # @return [ROM::Struct]
    #
    # @api public
    def [](name, attrs = {})
      registry[name].create(attrs)
    end
  end

  # A registry with all configured factories
  #
  # @api public
  class Factories
    extend Dry::Configurable

    setting :rom

    class << self
      # @!attribute [r] registry
      #   @return [Hash<Symbol=>Builder>]
      attr_reader :registry

      # @!attribute [r] structs
      #   @return [Structs] In-memory struct builder instance
      attr_reader :structs

      # @api private
      def inherited(klass)
        registry = {}
        klass.instance_variable_set(:'@registry', registry)
        klass.instance_variable_set(:'@structs', Structs.new(registry))
        super
      end

      # Define a new builder
      #
      # @example a simple builder
      #   MyFactory.define(:user) do |f|
      #     f.name "Jane"
      #     f.email "jane@doe.org"
      #   end
      #
      # @example a builder using auto-generated fake values
      #   MyFactory.define(:user) do |f|
      #     f.name { fake(:name) }
      #     f.email { fake(:internet, :email) }
      #   end
      #
      # @example a builder using sequenced values
      #   MyFactory.define(:user) do |f|
      #     f.sequence(:name) { |n| "user-#{n}" }
      #   end
      #
      # @example a builder using values from other attribute(s)
      #   MyFactory.define(:user) do |f|
      #     f.name "Jane"
      #     f.email { |name| "#{name.downcase}@rom-rb.org" }
      #   end
      #
      # @example a builder with "belongs-to" association
      #   MyFactory.define(:group) do |f|
      #     f.name "Admins"
      #   end
      #
      #   MyFactory.define(:user) do |f|
      #     f.name "Jane"
      #     f.association(:group)
      #   end
      #
      # @example a builder with "has-many" association
      #   MyFactory.define(:group) do |f|
      #     f.name "Admins"
      #     f.association(:users, count: 2)
      #   end
      #
      #   MyFactory.define(:user) do |f|
      #     f.sequence(:name) { |n| "user-#{n}" }
      #   end
      #
      # @example a builder which extends another builder
      #   MyFactory.define(:user) do |f|
      #     f.name "Jane"
      #     f.admin false
      #   end
      #
      #   MyFactory.define(admin: :user) do |f|
      #     f.admin true
      #   end
      #
      # @param [Symbol, Hash<Symbol=>Symbol>] Builder identifier, can point to a parent builder too
      # @param [Hash] opts Additional options
      # @option opts [Symbol] relation An optional relation name (defaults to pluralized builder name)
      #
      # @return [Builder]
      #
      # @api public
      def define(spec, **opts, &block)
        name, parent = spec.is_a?(Hash) ? spec.flatten(1) : spec

        if registry.key?(name)
          raise ArgumentError, "#{name.inspect} factory has been already defined"
        end

        builder =
          if parent
            extend_builder(name, registry[parent], &block)
          else
            relation_name = opts.fetch(:relation) { infer_relation(name) }
            relation = config.rom.relations[relation_name]
            DSL.new(name, relation: relation, factories: self, &block).call
          end

        registry[name] = builder
      end

      # Create and persist a new struct
      #
      # @example create a struct with default attributes
      #   MyFactory[:user]
      #
      # @example create a struct with some attributes overridden
      #   MyFactory[:user, name: "Jane"]
      #
      # @param [Symbol] name The name of the registered factory
      # @param [Hash] attrs An optional hash with attributes
      #
      # @return [ROM::Struct]
      #
      # @api public
      def [](name, attrs = {})
        registry[name].persistable.create(attrs)
      end

      # @api private
      def for_relation(relation)
        registry.fetch(infer_factory_name(relation.name.to_sym))
      end

      # @api private
      def infer_factory_name(name)
        ::Dry::Core::Inflector.singularize(name).to_sym
      end

      # @api private
      def infer_relation(name)
        ::Dry::Core::Inflector.pluralize(name).to_sym
      end

      # @api private
      def extend_builder(name, parent, &block)
        DSL.new(name, attributes: parent.attributes, relation: parent.relation, factories: self, &block).call
      end
    end
  end
end
