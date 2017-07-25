require 'rom'

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

  before do
    %i(tasks users).each { |t| conn.drop_table?(t) }

    conn.create_table(:users) do
      primary_key :id
      column :last_name, String, null: false
      column :first_name, String, null: false
      column :email, String, null: false
      column :created_at, Time, null: false
      column :updated_at, Time, null: false
      column :age, Integer
    end

    conn.create_table(:tasks) do
      primary_key :id
      foreign_key :user_id, :users
      column :title, String, null: false
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
  end
end
