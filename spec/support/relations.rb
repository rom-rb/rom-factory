module Test
  class UserRelation < ROM::Relation[:sql]
    schema(:users) do
      attribute :id, Types::Int
      attribute :last_name, Types::String
      attribute :first_name, Types::String
      attribute :email, Types::String
      attribute :age, Types::Int
      attribute :created_at, Types::Time
      attribute :updated_at, Types::Time

      primary_key :id

      associations do
        has_many :tasks
      end
    end
  end

  class TaskRelation < ROM::Relation[:sql]
    schema(:tasks) do
      attribute :id, Types::Int
      attribute :user_id, Types::Int
      attribute :title, Types::String

      primary_key :id

      associations do
        belongs_to :user
      end
    end
  end
end
