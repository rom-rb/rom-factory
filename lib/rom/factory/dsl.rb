require 'rom/factory/builder'

module ROM
  module Factory
    class DSL < BasicObject
      def initialize(name, relation: ::Dry::Core::Inflector.pluralize(name).to_sym, &block)
        Builder.define do |b|
          b.factory(name: name, relation: relation) do |f|
            @builder = f
            instance_exec(f, &block)
          end
        end

        def create(name)
          ::Factory[name]
        end

        def fake(*args)
          ::Factory.fake(*args)
        end

        def method_missing(meth, *args, &block)
          @builder.public_send(meth, *args, &block)
        end
      end
    end

    def self.define(name, **opts, &block)
      DSL.new(name, opts, &block)
    end

    def self.[](name, attrs = {})
      Builder.create(name, attrs)
    end

    def self.fake(type, *args)
      api = Faker.const_get(Dry::Core::Inflector.classify(type.to_s))
      meth, *rest = args

      if meth.is_a?(Symbol)
        api.public_send(meth, *rest)
      else
        api.public_send(type, *args)
      end
    end
  end
end
