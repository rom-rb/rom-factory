# frozen_string_literal: true

RSpec.describe ROM::Factory do
  include_context 'relations'

  subject(:factories) do
    ROM::Factory.configure do |config|
      config.rom = rom
    end
  end

  describe 'factory is not defined' do
    it 'raises error for persistable' do
      expect { factories[:not_defined] }
        .to raise_error(ROM::Factory::FactoryNotDefinedError)
    end

    it 'raises error for structs' do
      expect { factories.structs[:not_defined] }
        .to raise_error(ROM::Factory::FactoryNotDefinedError)
    end
  end

  describe '.structs' do
    it 'returns a plain struct builder' do
      factories.define(:user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
        f.timestamps
      end

      user1 = factories.structs[:user]
      user2 = factories.structs[:user]

      expect(user1.id).to_not be(nil)
      expect(user1.first_name).to eql('Jane')
      expect(user1.last_name).to_not be(nil)
      expect(user1.email).to_not be(nil)
      expect(user1.created_at).to_not be(nil)
      expect(user1.updated_at).to_not be(nil)

      expect(user1.id).to_not eql(user2.id)

      expect(rom.relations[:users].count).to be_zero

      expect(user1.class).to be(user2.class)
    end

    it 'works with one to many relationships when building parent' do
      factories.define(:task) do |f|
        f.sequence(:title) { |n| "Task #{n}" }
      end

      factories.define(:user) do |f|
        f.timestamps
        f.association(:tasks, count: 2)
      end

      user_with_tasks = factories.structs[:user]

      expect(user_with_tasks.tasks.length).to eql(2)
      expect(relations[:tasks].count).to be_zero
      expect(relations[:users].count).to be_zero
      expect(user_with_tasks.tasks).to all(respond_to(:title, :user_id))
      expect(user_with_tasks.tasks).to all(have_attributes(user_id: user_with_tasks.id))
    end

    it 'does not create records when building child' do
      factories.define(:task) do |f|
        f.sequence(:title) { |n| "Task #{n}" }
      end

      factories.define(:user) do |f|
        f.timestamps
        f.association(:tasks, count: 2)
      end

      factories.structs[:task]

      expect(relations[:tasks].count).to be_zero
      expect(relations[:users].count).to be_zero
    end

    context 'one-to-one' do
      let(:rom) do
        ROM.container(:sql, conn) do |conf|
          conf.default.create_table(:basic_users) do
            primary_key :id
          end

          conf.default.create_table(:basic_accounts) do
            primary_key :id
            foreign_key :basic_user_id, :basic_users
          end

          conf.relation(:basic_users) do
            schema(infer: true) do
              associations do
                has_one :basic_account
              end
            end
          end

          conf.relation(:basic_accounts) do
            schema(infer: true) do
              associations do
                belongs_to :basic_user
              end
            end
          end
        end
      end

      before do
        conn.drop_table?(:basic_accounts)
        conn.drop_table?(:basic_users)

        factories.define(:basic_user) do |f|
          f.association(:basic_account)
        end

        factories.define(:basic_account) do |f|
          f.association(:basic_user)
        end
      end

      it 'works with one to one relationships with parent' do
        user = factories.structs[:basic_user]

        expect(relations[:basic_accounts].count).to be_zero
        expect(relations[:basic_users].count).to be_zero
        expect(user.basic_account).to have_attributes(basic_user_id: user.id)
      end

      it 'does not persist when building a child struct' do
        factories.structs[:basic_account]

        expect(relations[:basic_accounts].count).to be_zero
        expect(relations[:basic_users].count).to be_zero
      end
    end
  end

  describe 'factories builder DSL' do
    it 'infers relation from the name' do
      factories.define(:user) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      user = factories[:user]

      expect(user.id).to_not be(nil)
      expect(user.first_name).to eql('Janis')
    end

    it 'raises an error if arguments are not part of schema' do
      expect {
        factories.define(:user, relation: :users) do |f|
          f.boobly 'Janis'
        end
      }.to raise_error(NoMethodError)
    end
  end

  context 'creation of records' do
    it 'creates a record based on defined factories' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user = factories[:user]

      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end

    it 'supports callable values' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at {Time.now}
        f.updated_at {Time.now}
      end

      user = factories[:user]

      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
      expect(user.created_at).not_to be_nil
      expect(user.updated_at).not_to be_nil
    end

    it 'supports rand inside the DSL' do
      factories.define(:user) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email { "janjiss+#{ rand(300) }@gmail.com" }
        f.created_at {Time.now}
        f.updated_at {Time.now}
      end

      user = factories[:user]
      expect(user.email).to match /\d{1,3}/
    end
  end

  context 'changing values' do
    it 'supports overwriting of values' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user = factories[:user, email: 'holla@gmail.com']

      expect(user.email).to eq('holla@gmail.com')
    end
  end

  context 'dependant attributes' do
    it 'passes generated value to the block of another attribute' do
      factories.define(:user, relation: :users) do |f|
        f.first_name { fake(:name) }
        f.last_name { fake(:name) }
        f.sequence(:email) { |i, first_name, last_name| "#{first_name}.#{last_name}@test-#{i}.org" }
        f.timestamps
      end

      user = factories[:user]

      expect(user.email).to eql("#{user.first_name}.#{user.last_name}@test-1.org")
    end
  end

  context 'changing values of dependant attributes' do
    it 'sets correct values to attributes with overwritten dependant attributes' do
      factories.define(:user) do |f|
        f.first_name { fake(:name) }
        f.last_name { fake(:name) }
        f.email { |last_name| "#{last_name}@gmail.com" }
        f.timestamps
      end

      overwritten_last_name = 'ivanov'
      user = factories[:user, last_name: overwritten_last_name ]

      expect(user.last_name).to eql(overwritten_last_name)
      expect(user.email).to eq("#{overwritten_last_name}@gmail.com")
    end
  end

  context 'incomplete schema' do
    it 'fills in missing attributes' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      user = factories[:user]

      expect(user.id).to_not be(nil)
      expect(user.age).to be(nil)
    end
  end

  context 'errors' do
    it 'raises error if factories with the same name is registered' do
      define = -> {
        factories.define(:user, relation: :users) { }
      }

      define.()

      expect { define.() }.to raise_error(ArgumentError)
    end
  end

  context 'sequence' do
    it 'supports sequencing of values' do
      factories.define(:user, relation: :users) do |f|
        f.sequence(:email) { |n| "janjiss#{n}@gmail.com" }
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user1 = factories[:user]
      user2 = factories[:user]

      expect(user1.email).to eq('janjiss1@gmail.com')
      expect(user2.email).to eq('janjiss2@gmail.com')
    end
  end

  context 'timestamps' do
    it 'creates timestamps, created_at and updated_at, based on callable property' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      user1 = factories[:user]
      sleep 1
      user2 = factories[:user]

      expect(user1.created_at.class).to eq(Time)
      expect(user1.updated_at.class).to eq(Time)

      expect(user2.created_at).not_to eq(user1.created_at)
      expect(user2.updated_at).not_to eq(user1.updated_at)
    end
  end

  context 'inheritance' do
    it 'sets up a new builder based on another' do
      factories.define(:user) do |f|
        f.timestamps
      end

      factories.define(jane: :user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
      end

      factories.define(john: :jane) do |f|
        f.first_name 'John'
        f.email 'john@doe.org'
      end

      jane = factories[:jane]
      john = factories[:john]

      expect(jane.first_name).to eql('Jane')
      expect(jane.email).to eql('jane@doe.org')

      expect(john.first_name).to eql('John')
      expect(john.last_name).to eql('Doe')
      expect(john.email).to eql('john@doe.org')
    end
  end

  context 'with traits' do
    it 'allows to define traits' do
      factories.define(:user) do |f|
        f.timestamps

        f.trait :jane do |t|
          t.first_name 'Jane'
          t.email 'jane@doe.org'
        end

        f.trait :doe do |t|
          t.last_name 'Doe'
        end
      end

      jane = factories.structs[:user, :jane]

      expect(jane.first_name).to eql('Jane')
      expect(jane.last_name).to eql nil
      expect(jane.email).to eql('jane@doe.org')

      jane_doe = factories.structs[:user, :jane, :doe]

      expect(jane_doe.first_name).to eql('Jane')
      expect(jane_doe.last_name).to eql('Doe')
      expect(jane_doe.email).to eql('jane@doe.org')
    end

    it 'allows to define nested traits' do
      factories.define(:user) do |f|
        f.timestamps

        f.trait :jane do |t|
          t.first_name 'Jane'
          t.email 'jane@doe.org'
        end

        f.trait :jane_doe, %i[jane] do |t|
          t.last_name 'Doe'
        end
      end

      jane = factories.structs[:user, :jane_doe]

      expect(jane.first_name).to eql('Jane')
      expect(jane.last_name).to eql('Doe')
      expect(jane.email).to eql('jane@doe.org')
    end

    it 'allows to define traits for persisted' do
      factories.define(:user) do |f|
        f.timestamps

        f.trait :jane do |t|
          t.first_name 'Jane'
          t.email 'jane@doe.org'
        end

        f.trait :doe do |t|
          t.last_name 'Doe'
        end
      end

      jane = factories[:user, :jane, :doe]

      expect(jane.first_name).to eql('Jane')
      expect(jane.last_name).to eql('Doe')
      expect(jane.email).to eql('jane@doe.org')
    end

    it 'allows to define traits with associations' do
      factories.define(:task) do |f|
        f.sequence(:title) { |n| "Task #{n}" }
      end

      factories.define(:user) do |f|
        f.timestamps

        f.trait :jane do |t|
          t.first_name 'Jane'
          t.email 'jane@doe.org'
        end

        f.trait :doe do |t|
          t.last_name 'Doe'
        end

        f.trait :with_tasks do |t|
          t.association(:tasks, count: 2)
        end
      end

      user = factories[:user, :jane, :doe]
      expect(user).not_to be_respond_to(:tasks)

      user_with_tasks = factories[:user, :jane, :doe, :with_tasks]

      expect(user_with_tasks.first_name).to eql('Jane')
      expect(user_with_tasks.last_name).to eql('Doe')
      expect(user_with_tasks.email).to eql('jane@doe.org')

      expect(user_with_tasks.tasks.count).to be(2)

      t1, t2 = user_with_tasks.tasks

      expect(t1.user_id).to be(user_with_tasks.id)
      expect(t1.title).to eql('Task 1')

      expect(t2.user_id).to be(user_with_tasks.id)
      expect(t2.title).to eql('Task 2')
    end
  end

  context 'faker' do
    it 'exposes faker API in the DSL' do
      factories.define(:user) do |f|
        f.first_name { fake(:name) }
        f.last_name { fake(:name, :last_name) }
        f.email { fake(:internet, :email) }
        f.timestamps
      end

      user = factories[:user]

      expect(user.id).to_not be(nil)
      expect(user.first_name).to_not be(nil)
      expect(user.last_name).to_not be(nil)
      expect(user.email).to_not be(nil)
      expect(user.created_at).to_not be(nil)
      expect(user.created_at).to_not be(nil)
    end
  end

  context 'custom non integer sequence primary_key' do
    let(:rom) do
      ROM.container(:sql, conn) do |conf|
        conf.default.create_table(:custom_primary_keys) do
          column :custom_id, String
          column :name, String
        end

        conf.relation(:custom_primary_keys) do
          schema(infer: true) do
            attribute :custom_id, ROM::SQL::Types::String.meta(primary_key: true)
          end
        end
      end
    end

    before do
      conn.drop_table?(:custom_primary_keys)
    end

    it "doesn't assume primary_key is an integer sequence" do
      factories.define(:custom_primary_key) do |f|
        f.custom_id { fake(:pokemon, :name) }
        f.name { fake(:name, :name) }
      end

      result = factories[:custom_primary_key]

      expect(result.custom_id).not_to be(nil)
      expect(result.custom_id).not_to be_a(Integer)
      expect(result.custom_id).to be_a(String)
    end

    it "doesn't assume primary_key is an integer sequence for a struct" do
      factories.define(:custom_primary_key) do |f|
        f.custom_id { fake(:pokemon, :name) }
        f.name { fake(:name, :name) }
      end

      result = factories.structs[:custom_primary_key]

      expect(result.custom_id).not_to be(nil)
      expect(result.custom_id).not_to be_a(Integer)
      expect(result.custom_id).to be_a(String)
    end
  end

  context 'using builders within callable blocks' do
    it 'exposes create method in callable attribute blocks' do
      factories.define(:user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
        f.timestamps
      end

      factories.define(:task) do |f|
        f.title 'A task'
        f.user_id { create(:user).id }
      end

      task = factories[:task]

      expect(task.title).to eql('A task')
      expect(task.user_id).to_not be(nil)
    end
  end

  context 'using associations' do
    context 'with traits' do
      before do
        factories.define(:user) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
          f.association(:tasks, :important, count: 2)
        end

        factories.define(:task) do |f|
          f.sequence(:title) { |n| "Task #{n}" }
          f.trait :important do |t|
            t.sequence(:title) { |n| "Important Task #{n}" }
          end
        end
      end

      it 'creates associated records with the given trait' do
        user = factories[:user]

        expect(user.tasks.count).to be(2)

        t1, t2 = user.tasks

        expect(t1.user_id).to be(user.id)
        expect(t1.title).to eql('Important Task 1')

        expect(t2.user_id).to be(user.id)
        expect(t2.title).to eql('Important Task 2')
      end
    end

    context 'has_many' do
      before do
        factories.define(:user) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
          f.association(:tasks, count: 2)
        end

        factories.define(:task) do |f|
          f.sequence(:title) { |n| "Task #{n}" }
        end
      end

      it 'creates associated records' do
        user = factories[:user]

        expect(user.tasks.count).to be(2)

        t1, t2 = user.tasks

        expect(t1.user_id).to be(user.id)
        expect(t1.title).to eql('Task 1')

        expect(t2.user_id).to be(user.id)
        expect(t2.title).to eql('Task 2')
      end
    end

    context 'belongs_to' do
      before do
        factories.define(:user) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
        end

        factories.define(:task) do |f|
          f.title 'A task'
          f.association(:user)
        end
      end

      it 'exposes create method in callable attribute blocks' do
        task = factories[:task]

        expect(task.title).to eql('A task')
        expect(task.user_id).to_not be(nil)
      end

      it 'allows overrides' do
        user = factories[:user, name: "Joe"]
        task = factories[:task, user: user]

        expect(task.title).to eql('A task')
        expect(task.user_id).to be(user.id)

        expect(rom.relations[:users].count).to be(1)
        expect(rom.relations[:tasks].count).to be(1)
      end

      it 'works with structs' do
        user = factories.structs[:user, name: "Joe"]
        task = factories.structs[:task, user: user]

        expect(task.title).to eql('A task')
        expect(task.user_id).to be(user.id)

        expect(rom.relations[:users].count).to be(0)
        expect(rom.relations[:tasks].count).to be(0)
      end
    end
  end

  context 'without PK' do
    let(:rom) do
      ROM.container(:sql, conn) do |conf|
        conf.default.create_table(:dummies) do
          column :id, Integer, default: 1
          column :name, String, null: false
        end

        conf.relation(:dummies) do
          schema(infer: true) do
            attribute :id, ROM::SQL::Types::Serial
          end
        end
      end
    end

    before do
      conn.drop_table?(:dummies)
    end

    it 'works even if the table does not have a PK' do
      factories.define(:dummy) do |f|
        f.name 'Jane'
      end

      result = factories[:dummy]

      expect(result.id).to be(1)
      expect(result.name).to eql('Jane')
    end
  end

  context 'with custom struct namespace' do
    let(:entities) { factories.struct_namespace(Test::Entities) }

    before do
      module Test
        module Entities
          class User < ROM::Struct
          end
        end
      end

      factories.define(:user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
        f.timestamps
      end
    end

    context 'using in-memory structs' do
      it 'returns an instance of a custom struct' do
        result = entities.structs[:user]

        expect(result).to be_kind_of(Test::Entities::User)

        expect(result.id).to be(1)
        expect(result.first_name).to eql('Jane')
        expect(result.last_name).to eql('Doe')
        expect(result.email).to eql('jane@doe.org')
        expect(result.created_at).to_not be(nil)
        expect(result.updated_at).to_not be(nil)
      end
    end

    context 'using persistable structs' do
      it 'returns an instance of a custom struct' do
        result = entities[:user]

        expect(result).to be_kind_of(Test::Entities::User)

        expect(result.id).to be(1)
        expect(result.first_name).to eql('Jane')
        expect(result.last_name).to eql('Doe')
        expect(result.email).to eql('jane@doe.org')
        expect(result.created_at).to_not be(nil)
        expect(result.updated_at).to_not be(nil)
      end
    end
  end

  describe 'using read types with one-to-many' do
    before do
      conf.relation(:capitalized_tasks) do
        schema(:tasks, infer: true) do
          attribute :title, ROM::SQL::Types::String.meta(
            read: ROM::SQL::Types::String.constructor(&:upcase)
          )

          associations do
            belongs_to :user
          end
        end
      end
    end

    specify do
      factories.define(:capitalized_task) do |f|
        f.title 'A task'
        f.association(:user)
      end

      factories.define(:user) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      task = factories.structs[:capitalized_task]

      expect(task.title).to eql('A TASK')
      expect(task.user.first_name).to eql('Janis')
    end
  end
end
