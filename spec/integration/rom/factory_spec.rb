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

    context 'one-to-many' do
      before do
        factories.define(:task) do |f|
          f.sequence(:title) { |n| "Task #{n}" }
        end

        factories.define(:user) do |f|
          f.timestamps
          f.association(:tasks, count: 2)
        end
      end

      it 'works when building parent' do
        user_with_tasks = factories.structs[:user]

        expect(user_with_tasks.tasks.length).to eql(2)
        expect(relations[:tasks].count).to be_zero
        expect(relations[:users].count).to be_zero
        expect(user_with_tasks.tasks).to all(respond_to(:title, :user_id))
        expect(user_with_tasks.tasks).to all(have_attributes(user_id: user_with_tasks.id))
      end

      it 'does not create records when building child' do
        factories.structs[:task]

        expect(relations[:tasks].count).to be_zero
        expect(relations[:users].count).to be_zero
      end

      it 'does not pass provided attributes into associations' do
        expect {
          factories.structs[:user, email: 'jane@doe.com']
        }.not_to raise_error
      end
    end

    context 'many-to-one' do
      before do
        factories.define(:task) do |f|
          f.title { 'Foo' }
          f.association(:user)
        end

        factories.define(:user) do |f|
          f.timestamps
        end
      end

      it 'does not pass provided attributes into associations' do
        expect { factories.structs[:task, title: 'Bar'] }.not_to raise_error
      end
    end

    context 'one-to-one-through' do
      before do
        factories.define(:user) do |f|
          f.first_name 'Janis'
          f.last_name 'Miezitis'
          f.email 'janjiss@gmail.com'
          f.timestamps

          f.association :address
        end

        factories.define(:address) do |f|
          f.full_address '123 Elm St.'
        end
      end

      context 'when persisting' do
        it 'creates the correct records when the is no pre-existing entity' do
          user = factories[:user]

          expect(user.address).to have_attributes(full_address: '123 Elm St.')
        end

        it 'creates the join table record when there is a pre-existing entity' do
          address = factories[:address]
          user = factories[:user, address: address]

          expect(user.address).to have_attributes(full_address: '123 Elm St.')
        end
      end

      context 'when building a struct' do
        it 'persists the relation properly with pre-existing assoc record' do
          skip 'TODO: This does not work, cannot figure out why'

          address = factories.structs[:address]
          user = factories.structs[:user, address: address]

          expect(user.address).to have_attributes(full_address: '123 Elm St.')
        end

        it 'persists the relation properly without pre-existing assoc record' do
          skip 'TODO: This does not work, cannot figure out why'

          user = factories.structs[:user]

          expect(user.address).to have_attributes(full_address: '123 Elm St.')
        end
      end
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
            column :created_at, Time, null: false
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

      context 'when both factories define the associations' do
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

        it 'does not pass provided attributes into associations' do
          expect {
            factories.structs[:basic_account, created_at: Time.now]
          }.not_to raise_error
        end
      end

      context 'when the child factory does not define the parent association' do
        before do
          conn.drop_table?(:basic_accounts)
          conn.drop_table?(:basic_users)

          factories.define(:basic_user) do |f|
            f.association(:basic_account)
          end

          factories.define(:basic_account) do |f|
          end
        end

        it 'still allows building the parent struct' do
          basic_user = factories.structs[:basic_user]

          expect(basic_user.basic_account).to respond_to(:id)
        end
      end

      context 'when the count is specified as 0' do
        before do
          conn.drop_table?(:basic_accounts)
          conn.drop_table?(:basic_users)

          factories.define(:basic_user) do |f|
            f.association(:basic_account, count: 0)
          end

          factories.define(:basic_account) do |f|
            f.association(:basic_user)
          end
        end

        it 'does not create the related record' do
          user = factories[:basic_user]

          expect(user.basic_account).to be_nil
        end

        it 'does not build the related record' do
          user = factories.structs[:basic_user]

          expect(user.basic_account).to be_nil
        end
      end

      context 'when the count is greater than 0' do
        before do
          conn.drop_table?(:basic_accounts)
          conn.drop_table?(:basic_users)
        end

        it 'raises an ArgumentError' do
          defining_with_count_greater_than_zero = proc do
            factories.define(:basic_user) do |f|
              f.association(:basic_account, count: 2)
            end
          end

          expect(&defining_with_count_greater_than_zero).to raise_error(ArgumentError)
        end
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
      expect(user.email).to match(/\d{1,3}/)
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

    it 'raises error when trying to set missing attribute' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      expect {
        factories[:user, not_real_attribute: "invalid attribute value"]
      }.to raise_error(ROM::Factory::UnknownFactoryAttributes)
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
    context 'without struct_namespace option' do
      before do
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
      end
      context 'using in-memory structs' do
        let(:jane) { factories.structs[:jane] }
        let(:john) { factories.structs[:john] }

        it 'sets up a new builder based on another' do
          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')

          expect(john.first_name).to eql('John')
          expect(john.last_name).to eql('Doe')
          expect(john.email).to eql('john@doe.org')
        end
      end

      context 'using persistable structs' do
        let(:jane) { factories[:jane] }
        let(:john) { factories[:john] }

        it 'sets up a new builder based on another' do
          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')

          expect(john.first_name).to eql('John')
          expect(john.last_name).to eql('Doe')
          expect(john.email).to eql('john@doe.org')
        end
      end
    end

    context 'with struct_namespace option' do
      before do
        module Test
          module Entities
            class User < ROM::Struct
            end
          end

          module AnotherEntities
            class Admin < ROM::Struct
            end
          end
        end

        factories.define(:user, struct_namespace: Test::Entities) do |f|
          f.timestamps
        end

        factories.define(jane: :user) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
        end

        factories.define({admin: :jane}, struct_namespace: Test::AnotherEntities) do |f|
          f.type 'Admin'
        end

        factories.define({ john: :jane }, struct_namespace: Test::AnotherEntities) do |f|
          f.first_name 'John'
          f.email 'john@doe.org'
        end
      end

      context 'using in-memory structs' do
        let(:jane) { factories.structs[:jane] }
        let(:john) { factories.structs[:john] }
        let(:admin) { factories.structs[:admin] }

        it 'sets up a new builder based on another with correct struct_namespace' do
          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')
          expect(jane).to be_kind_of(Test::Entities::User)

          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')
          expect(admin.type).to eql('Admin')
          expect(admin).to be_kind_of(Test::AnotherEntities::Admin)

          expect(john.first_name).to eql('John')
          expect(john.last_name).to eql('Doe')
          expect(john.email).to eql('john@doe.org')
          expect(john).to be_kind_of(Test::AnotherEntities::User)
        end
      end

      context 'using persistable structs' do
        let(:jane) { factories[:jane] }
        let(:john) { factories[:john] }
        let(:admin) { factories[:admin] }

        it 'sets up a new builder based on another with correct struct_namespace' do
          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')
          expect(jane).to be_kind_of(Test::Entities::User)

          expect(jane.first_name).to eql('Jane')
          expect(jane.email).to eql('jane@doe.org')
          expect(admin.type).to eql('Admin')
          expect(admin).to be_kind_of(Test::AnotherEntities::Admin)

          expect(john.first_name).to eql('John')
          expect(john.last_name).to eql('Doe')
          expect(john.email).to eql('john@doe.org')
          expect(john).to be_kind_of(Test::AnotherEntities::User)
        end
      end
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
        f.custom_id { fake(:color, :color_name) }
        f.name { fake(:name, :name) }
      end

      result = factories[:custom_primary_key]

      expect(result.custom_id).not_to be(nil)
      expect(result.custom_id).not_to be_a(Integer)
      expect(result.custom_id).to be_a(String)
    end

    it "doesn't assume primary_key is an integer sequence for a struct" do
      factories.define(:custom_primary_key) do |f|
        f.custom_id { fake(:color, :color_name) }
        f.name { fake(:name, :name) }
      end

      result = factories.structs[:custom_primary_key]

      expect(result.custom_id).not_to be(nil)
      expect(result.custom_id).not_to be_a(Integer)
      expect(result.custom_id).to be_a(String)
    end
  end

  context 'with a custom output schema' do
    it "doesn't assume primary_key exists" do
      factories.define(:key_values) do |f|
        f.key 'a_key'
        f.value 'a_value'
      end

      result = factories[:key_values]

      expect(result.key).to eql('a_key')
      expect(result.value).to eql('a_value')
    end

    it "doesn't assume primary_key exists for a struct" do
      factories.define(:key_values) do |f|
        f.key 'a_key'
        f.value 'a_value'
      end

      result = factories.structs[:key_values]

      expect(result.key).to eql('a_key')
      expect(result.value).to eql('a_value')
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
        user = factories[:user, first_name: "Joe"]
        task = factories[:task, user: user]

        expect(task.title).to eql('A task')
        expect(task.user_id).to be(user.id)

        expect(rom.relations[:users].count).to be(1)
        expect(rom.relations[:tasks].count).to be(1)
      end

      it 'works with structs' do
        user = factories.structs[:user, first_name: 'Joe']
        task = factories.structs[:task, user: user]

        expect(user.first_name).to eql('Joe')
        expect(task.title).to eql('A task')
        expect(task.user_id).to be(user.id)

        expect(rom.relations[:users].count).to be(0)
        expect(rom.relations[:tasks].count).to be(0)
      end

      it 'raises UnknownFactoryAttributes when unknown attributes are used' do
        expect { factories.structs[:user, name: 'Joe'] }
          .to raise_error(ROM::Factory::UnknownFactoryAttributes, /name/)
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

  context 'facotry without custom struct namespace' do
    context 'with builder without custom struct namespace' do
      before do
        factories.define(:user) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
        end
      end

      context 'using in-memory structs' do
        it 'returns an instance of a default struct' do
          result = factories.structs[:user]

          expect(result).to be_kind_of(ROM::Struct::User)

          expect(result.id).to be(1)
          expect(result.first_name).to eql('Jane')
          expect(result.last_name).to eql('Doe')
          expect(result.email).to eql('jane@doe.org')
          expect(result.created_at).to_not be(nil)
          expect(result.updated_at).to_not be(nil)
        end
      end

      context 'using persistable structs' do
        it 'returns an instance of a default struct' do
          result = factories[:user]

          expect(result).to be_kind_of(ROM::Struct::User)

          expect(result.id).to be(1)
          expect(result.first_name).to eql('Jane')
          expect(result.last_name).to eql('Doe')
          expect(result.email).to eql('jane@doe.org')
          expect(result.created_at).to_not be(nil)
          expect(result.updated_at).to_not be(nil)
        end
      end
    end

    context 'with builder with custom struct namespace' do
      before do
        module Test
          module Entities
            class User < ROM::Struct
            end
          end
        end

        factories.define(:user, struct_namespace: Test::Entities) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
        end
      end

      context 'using in-memory structs' do
        it 'returns an instance of a custom struct' do
          result = factories.structs[:user]

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
          result = factories[:user]

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
  end

  context 'facotry with custom struct namespace' do
    context 'with builder without custom struct namespace' do
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

    context 'with builder with custom struct namespace' do
      let(:entities) { factories.struct_namespace(Test::Entities) }

      before do
        module Test
          module Entities
            class User < ROM::Struct
            end
          end

          module AnotherEntities
            class User < ROM::Struct
            end
          end
        end

        factories.define(:user, struct_namespace: Test::AnotherEntities) do |f|
          f.first_name 'Jane'
          f.last_name 'Doe'
          f.email 'jane@doe.org'
          f.timestamps
        end
      end

      context 'using in-memory structs' do
        it 'returns an instance of a custom struct' do
          result = entities.structs[:user]

          expect(result).to be_kind_of(Test::AnotherEntities::User)

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

          expect(result).to be_kind_of(Test::AnotherEntities::User)

          expect(result.id).to be(1)
          expect(result.first_name).to eql('Jane')
          expect(result.last_name).to eql('Doe')
          expect(result.email).to eql('jane@doe.org')
          expect(result.created_at).to_not be(nil)
          expect(result.updated_at).to_not be(nil)
        end
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

  unless ENV['FAKER'].eql?('faker-1')
    describe 'fake options' do
      specify do
        factories.define(:user) do |f|
          f.first_name 'Jane'
          f.age { fake(:number, :within, range: 0..150) }
        end

        user = factories.structs[:user]
        expect(user.age).to be_between(0, 150)
      end
    end
  end
end
