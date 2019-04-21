# frozen_string_literal: true

require 'dry/core/class_builder'
require 'rom/factory/factories'

module ROM
  # Main ROM::Factory API
  #
  # @api public
  module Factory
    DEFAULT_NAME = 'Factories'.freeze

    # Configure a new factory
    #
    # @example
    #   MyFactory = ROM::Factory.configure do |config|
    #     config.rom = my_rom_container
    #   end
    #
    # @param [Symbol] name An optional factory class name
    #
    # @return [Class]
    #
    # @api public
    def self.configure(name = DEFAULT_NAME, &block)
      klass = Dry::Core::ClassBuilder.new(name: name, parent: Factories).call do |klass|
        klass.configure(&block)
      end

      klass.new(klass.config.rom)
    end
  end
end
