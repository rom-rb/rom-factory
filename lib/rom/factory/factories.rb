require 'dry/configurable'
require 'dry/core/inflector'

require 'rom/factory/dsl'

module ROM::Factory
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
end
