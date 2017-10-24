require 'rom/factory/builder'

RSpec.describe ROM::Factory::Builder do
  subject(:builder) do
    ROM::Factory::Builder.new(ROM::Factory::AttributeRegistry.new(attributes), relation).persistable
  end

  include_context 'database'

  let(:factories) do
    ROM::Factory.configure do |config|
      config.rom = rom
    end
  end

  describe 'dependant attributes' do
    let(:attributes) do
      [attribute(:Callable, :email) { |name| "#{name.downcase}@rom-rb.org" },
       attribute(:Value, :name, 'Jane')]
    end

    let(:relation) { relations[:users] }

    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String
        column :email, String
      end

      conf.relation(:users) do
        schema(infer: true)
      end
    end

    after do
      conn.drop_table(:users)
    end

    it 'evaluates attributes in correct order' do
      user = builder.create

      expect(user.name).to eql('Jane')
      expect(user.email).to eql('jane@rom-rb.org')
    end
  end

  describe 'belongs_to association' do
    let(:attributes) do
      [attribute(:Value, :title, 'To-do'),
       attribute(:Association, tasks.associations[:user], -> { factories.registry[:user] })]
    end

    let(:tasks) { relations[:tasks] }
    let(:users) { relations[:users] }
    let(:relation) { tasks }

    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String
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
        schema(infer: true)
      end

      factories.define(:user) do |f|
        f.name 'Jane'
      end
    end

    after do
      conn.drop_table(:tasks)
      conn.drop_table(:users)
    end

    describe '#create' do
      it 'builds associated struct' do
        task = builder.create

        expect(task.title).to eql('To-do')
        expect(task.user.name).to eql('Jane')
      end
    end
  end

  describe 'has_many association' do
    let(:attributes) do
      [attribute(:Value, :name, 'Jane'),
       attribute(:Association, users.associations[:tasks], -> { factories.registry[:task] }, count: 2)]
    end

    let(:tasks) { relations[:tasks] }
    let(:users) { relations[:users] }
    let(:relation) { users }

    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String
      end

      conn.create_table(:tasks) do
        primary_key :id
        foreign_key :user_id, :users, null: false
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

      factories.define(:task) do |f|
        f.sequence(:title) { |n| "Task #{n}" }
      end
    end

    after do
      conn.drop_table(:tasks)
      conn.drop_table(:users)
    end

    describe '#create' do
      it 'builds associated structs' do
        user = builder.create

        expect(user.name).to eql('Jane')
        expect(user.tasks.size).to be(2)

        t1, t2 = user.tasks

        expect(t1.title).to eql('Task 1')
        expect(t1.user_id).to be(user.id)

        expect(t2.title).to eql('Task 2')
        expect(t2.user_id).to be(user.id)
      end
    end
  end

  describe 'has_one association' do
    let(:attributes) do
      [attribute(:Value, :name, 'Jane'),
       attribute(:Association, users.associations[:tasks], -> { factories.registry[:task] })]
    end

    let(:tasks) { relations[:tasks] }
    let(:users) { relations[:users] }
    let(:relation) { users }

    before do
      conn.create_table(:users) do
        primary_key :id
        column :name, String
      end

      conn.create_table(:tasks) do
        primary_key :id
        foreign_key :user_id, :users, null: false
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
            has_one :task
          end
        end
      end

      factories.define(:task) do |f|
        f.title 'To-do'
      end
    end

    after do
      conn.drop_table(:tasks)
      conn.drop_table(:users)
    end

    describe '#create' do
      it 'builds associated structs' do
        user = builder.create

        expect(user.name).to eql('Jane')
        expect(user.task.title).to eql('To-do')
        expect(user.task.user_id).to be(user.id)
      end
    end
  end
end
