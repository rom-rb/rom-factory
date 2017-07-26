require 'dry/configurable'
require 'dry/core/inflector'

require 'rom/factory/dsl'
require 'rom/factory/constants'
require 'rom/factory/registry'

module ROM::Factory
  class Structs
    attr_reader :registry

    def initialize(registry)
      @registry = registry
    end

    def [](name, attrs = {})
      registry[name].create(attrs)
    end
  end

  class Factories
    extend Dry::Configurable

    setting :rom

    class << self
      attr_reader :registry

      attr_reader :structs

      def inherited(klass)
        registry = Registry.new
        klass.instance_variable_set(:'@registry', registry)
        klass.instance_variable_set(:'@structs', Structs.new(registry))
        super
      end

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

      def for_relation(relation)
        registry.fetch(infer_factory_name(relation.name.to_sym))
      end

      def infer_factory_name(name)
        ::Dry::Core::Inflector.singularize(name).to_sym
      end

      def infer_relation(name)
        ::Dry::Core::Inflector.pluralize(name).to_sym
      end

      def extend_builder(name, parent, &block)
        DSL.new(name, attributes: parent.attributes, relation: parent.relation, factories: self, &block).call
      end

      def [](name, attrs = {})
        registry[name].persistable.create(attrs)
      end
    end
  end
end
