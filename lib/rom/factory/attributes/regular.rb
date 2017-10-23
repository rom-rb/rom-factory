module ROM::Factory
  module Attributes
    class Regular
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def call(attrs = {})
        return if attrs.key?(name)

        { name => value }
      end

      def dependency?(*)
        false
      end

      def dependency_names
        []
      end
    end
  end
end
