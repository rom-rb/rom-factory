require 'rom'

RSpec.shared_context 'database' do
  let(:conf) do
    Test::CONF
  end

  let(:rom) do
    Test::ROM
  end

  let(:conn) do
    Test::CONN
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
  end
end
