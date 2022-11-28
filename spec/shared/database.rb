# frozen_string_literal: true

require "rom/setup"

RSpec.shared_context "database" do
  let(:conf) do
    ROM::Setup.new(:sql, DB_URI)
  end

  let(:rom) do
    ROM.setup(conf)
  end

  let(:conn) do
    conf.registry.gateways[:default].connection
  end

  let(:relations) do
    rom.relations
  end
end
