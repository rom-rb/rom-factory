module RomFactory
  module Attributes
    class Regular
      def initialize(value)
        @value = value
      end

      def call
        @value
      end
    end
  end
end
