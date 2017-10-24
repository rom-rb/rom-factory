module ROM::Factory
  module Attributes
    # @api private
    module Association
      def self.new(assoc, builder, options = {})
        const_get(assoc.definition.type).new(assoc, builder, options)
      end

      # @api private
      class Core
        attr_reader :assoc, :options

        # @api private
        def initialize(assoc, builder, options = {})
          @assoc = assoc
          @builder_proc = builder
          @options = options
        end

        # @api private
        def builder
          @__builder__ ||= @builder_proc.()
        end

        # @api private
        def name
          assoc.key
        end

        # @api private
        def dependency?(*)
          false
        end

        # @api private
        def value?
          false
        end

        # @api private
        def dependency_names
          []
        end
      end

      # @api private
      class ManyToOne < Core
        # @api private
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

        # @api private
        def foreign_key
          assoc.foreign_key
        end
      end

      # @api private
      class OneToMany < Core
        # @api private
        def call(attrs = {}, parent)
          return if attrs.key?(name)

          structs = count.times.map {
            builder.persistable.create(assoc.associate(attrs, parent))
          }

          { name => structs }
        end

        # @api private
        def dependency?(rel)
          assoc.source == rel
        end

        # @api private
        def count
          options.fetch(:count)
        end
      end

      # @api private
      class OneToOne < OneToMany
        # @api private
        def call(attrs = {}, parent)
          return if attrs.key?(name)

          struct = builder.persistable.create(assoc.associate(attrs, parent))

          { name => struct }
        end
      end
    end
  end
end
