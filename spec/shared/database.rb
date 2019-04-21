# frozen_string_literal: true

require 'rom-core'

RSpec.shared_context 'database' do
  let(:conf) do
    ROM::Configuration.new(:sql, DB_URI)
  end

  let(:rom) do
    ROM.container(conf)
  end

  let(:conn) do
    conf.gateways[:default].connection
  end

  let(:relations) do
    rom.relations
  end
end
