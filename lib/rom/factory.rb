require 'dry-configurable'
require 'dry-container'

module ROM
  module Factory
    class Factories
      extend Dry::Configurable

      setting :rom
      setting :registry, {}

      def self.define(name, **opts, &block)
        if config.registry.key?(name)
          raise ArgumentError, "#{name.inspect} factory has been already defined"
        end

        relation_name = opts.fetch(:relation) do
          infer_relation(name)
        end

        relation = config.rom.relations[relation_name]

        builder = DSL.new(name, relation: relation, factories: self, &block).call

        config.registry[name] = builder
      end

      def self.infer_relation(name)
        ::Dry::Core::Inflector.pluralize(name).to_sym
      end

      def self.[](name, attrs = {})
        config.registry[name].create(attrs)
      end
    end

    DEFAULT_NAME = 'Factories'.freeze

    def self.configure(name = DEFAULT_NAME, &block)
      Dry::Core::ClassBuilder.new(name: name, parent: Factories).call do |klass|
        klass.configure(&block)
      end
    end
  end
end

require 'rom/factory/version'
require 'rom/factory/dsl'
require 'rom/factory/builder'
require 'rom/factory/factory'
require 'rom/factory/struct'
require 'rom/factory/attributes/callable'
require 'rom/factory/attributes/regular'
require 'rom/factory/attributes/sequence'
