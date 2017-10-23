module ROM::Factory
  module Attributes
    class Association
      attr_reader :assoc, :builder

      def initialize(assoc, builder)
        @assoc = assoc
        @builder = builder
      end

      def call(attrs = {})
        if attrs.key?(name) && !attrs.key?(foreign_key)
          { foreign_key => attrs[name].public_send(target_key) }
        else
          struct = builder.persistable.create
          tuple = { name => struct }

          if attrs.key?(foreign_key)
            tuple
          else
            tuple.merge(foreign_key => struct.public_send(target_key))
          end
        end
      end

      def name
        assoc.key
      end

      def target_key
        assoc.target.primary_key
      end

      def foreign_key
        assoc.foreign_key
      end
    end
  end
end
