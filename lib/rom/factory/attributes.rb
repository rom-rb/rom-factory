# frozen_string_literal: true

require 'dry/core/constants'

module ROM
  module Factory
    include Dry::Core::Constants
  end
end

require 'rom/factory/attributes/value'
require 'rom/factory/attributes/callable'
require 'rom/factory/attributes/sequence'
require 'rom/factory/attributes/association'
