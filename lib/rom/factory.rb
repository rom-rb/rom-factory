require 'dry/core/class_builder'
require 'rom/factory/factories'

module ROM
  module Factory
    DEFAULT_NAME = 'Factories'.freeze

    def self.configure(name = DEFAULT_NAME, &block)
      Dry::Core::ClassBuilder.new(name: name, parent: Factories).call do |klass|
        klass.configure(&block)
      end
    end
  end
end
