# frozen_string_literal: true

RSpec.shared_context 'relations' do
  include_context 'database'

  before do
    conn.create_table(:users) do
      primary_key :id
      column :last_name, String, null: false
      column :first_name, String, null: false
      column :email, String, null: false
      column :created_at, Time, null: false
      column :updated_at, Time, null: false
      column :age, Integer
      column :type, String
    end

    conn.create_table(:tasks) do
      primary_key :id
      foreign_key :user_id, :users
      column :title, String, null: false
    end

    conn.create_table(:key_values) do
      column :key, String
      column :value, String
    end

    conf.relation(:tasks) do
      schema(infer: true) do
        associations do
          belongs_to :user
        end
      end
    end

    conf.relation(:users) do
      schema(infer: true) do
        associations do
          has_many :tasks
        end
      end
    end

    conf.relation(:admins) do
      dataset { where(type: "Admin") }

      schema(:users, as: :admins, infer: true) do
        associations do
          has_many :tasks
        end
      end
    end

    conf.relation(:key_values) do
      option :output_schema, default: -> do
        ROM::Types::Hash.schema(
          schema.map { |attr| [attr.key, attr.to_read_type] }.to_h
        ).with_key_transform(&:to_sym)
      end

      schema(infer: true) {}
    end
  end

  after do
    conn.drop_table(:tasks)
    conn.drop_table(:users)
    conn.drop_table(:key_values)
  end
end
