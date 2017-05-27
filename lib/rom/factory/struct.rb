require 'dry/struct'
require 'dry/core/cache'
require 'dry/core/class_builder'

module ROM::Factory
  class Struct < Dry::Struct
    extend Dry::Core::Cache

    def self.define(name, schema)
      fetch_or_store(schema) do
        id = Dry::Core::Inflector.classify(Dry::Core::Inflector.singularize(name))

        Dry::Core::ClassBuilder.new(name: id, parent: self, namespace: self).call do |klass|
          schema.each do |attr|
            klass.attribute attr.name, attr.type
          end
        end
      end
    end
  end
end
