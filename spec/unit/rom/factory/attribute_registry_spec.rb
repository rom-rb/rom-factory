# frozen_string_literal: true

require 'rom/factory/attribute_registry'

RSpec.describe ROM::Factory::AttributeRegistry do
  subject(:registry) { ROM::Factory::AttributeRegistry.new(elements) }

  let(:elements) do
    [email_attr, id_attr, name_attr]
  end

  let(:name_attr) do
    value(:name, 'Jane')
  end

  let(:email_attr) do
    callable(:email) { |name| "#{name}@rom-rb.org" }
  end

  let(:id_attr) do
    sequence(:id) { |n| n }
  end

  describe '#tsort' do
    it 'sorts attributes by their dependencies' do
      expect(registry.tsort).to eql([name_attr, email_attr, id_attr])
    end
  end
end
