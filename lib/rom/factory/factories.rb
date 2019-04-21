# frozen_string_literal: true

require 'dry/configurable'
require 'dry/core/inflector'

require 'rom/initializer'
require 'rom/struct'
require 'rom/factory/dsl'
require 'rom/factory/registry'

module ROM::Factory
  # In-memory builder API
  #
  # @api public
  class Structs
    # @!attribute [r] registry
    #   @return [Hash<Symbol=>Builder>]
    attr_reader :registry

    # @!attribute [r] struct_namespace
    #   @return [Module]
    attr_reader :struct_namespace

    # @api private
    def initialize(registry, struct_namespace)
      @registry = registry
      @struct_namespace = struct_namespace
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
    def [](name, *traits, **attrs)
      registry[name].struct_namespace(struct_namespace).create(*traits, attrs)
    end
  end

  # A registry with all configured factories
  #
  # @api public
  class Factories
    extend Dry::Configurable
    extend ROM::Initializer

    setting :rom

    # @!attribute [r] rom
    #   @return [ROM::Container] configured rom container
    param :rom

    # @!attribute [r] struct_namespace
    #   @return [Structs] in-memory struct builder instance
    option :struct_namespace, optional: true, default: proc { ROM::Struct }

    # @!attribute [r] registry
    #   @return [Hash<Symbol=>Builder>] a map with defined db-backed builders
    option :registry, default: proc { Registry.new }

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
    # @param [Symbol, Hash<Symbol=>Symbol>] spec Builder identifier, can point to a parent builder too
    # @param [Hash] opts Additional options
    # @option opts [Symbol] relation An optional relation name (defaults to pluralized builder name)
    #
    # @return [ROM::Factory::Builder]
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
          relation = rom.relations[relation_name]
          DSL.new(name, relation: relation.struct_namespace(struct_namespace), factories: self, &block).call
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
    def [](name, *traits, **attrs)
      registry[name].persistable(struct_namespace).create(*traits, attrs)
    end

    # Return in-memory struct builder
    #
    # @return [Structs]
    #
    # @api public
    def structs
      @__structs__ ||= Structs.new(registry, struct_namespace)
    end

    # Get factories with a custom struct namespace
    #
    # @example
    #   EntityFactory = MyFactory.struct_namespace(MyApp::Entities)
    #
    #   EntityFactory[:user]
    #   # => #<MyApp::Entities::User id=2 ...>
    #
    # @param [Module] namespace
    #
    # @return [Factories]
    #
    # @api public
    def struct_namespace(namespace = Undefined)
      if namespace.equal?(Undefined)
        options[:struct_namespace]
      else
        with(struct_namespace: namespace)
      end
    end

    # @api private
    def for_relation(relation)
      registry[infer_factory_name(relation.name.to_sym)]
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
