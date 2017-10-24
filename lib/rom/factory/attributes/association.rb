module ROM::Factory
  module Attributes
    module Association
      def self.new(assoc, builder, options = {})
        const_get(assoc.definition.type).new(assoc, builder, options)
      end

      class Core
        attr_reader :assoc, :options

        def initialize(assoc, builder, options = {})
          @assoc = assoc
          @builder_proc = builder
          @options = options
        end

        def builder
          @__builder__ ||= @builder_proc.()
        end

        def name
          assoc.key
        end

        def dependency?(*)
          false
        end

        def value?
          false
        end

        def dependency_names
          []
        end
      end

      class ManyToOne < Core
        def call(attrs = {})
          if attrs.key?(name) && !attrs.key?(foreign_key)
            assoc.associate(attrs, attrs[name])
          else
            struct = builder.persistable.create
            tuple = { name => struct }

            if attrs.key?(foreign_key)
              tuple
            else
              assoc.associate(tuple, struct)
            end
          end
        end

        def foreign_key
          assoc.foreign_key
        end
      end

      class OneToMany < Core
        def call(attrs = {}, parent)
          return if attrs.key?(name)

          structs = count.times.map {
            builder.persistable.create(assoc.associate(attrs, parent))
          }

          { name => structs }
        end

        def dependency?(rel)
          assoc.source == rel
        end

        def count
          options.fetch(:count)
        end
      end

      class OneToOne < OneToMany
        def call(attrs = {}, parent)
          return if attrs.key?(name)

          struct = builder.persistable.create(assoc.associate(attrs, parent))

          { name => struct }
        end
      end
    end
  end
end
