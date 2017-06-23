RSpec.describe ROM::Factory do
  subject(:factories) do
    ROM::Factory.configure do |config|
      config.rom = rom
    end
  end

  let(:uri) do |example|
    meta = example.metadata
    adapters = ADAPTERS.select { |adapter| meta[adapter] }

    case adapters.size
    when 1 then DB_URIS.fetch(adapters.first)
    when 0 then raise 'No adapter specified'
    else
      raise "Ambiguous adapter configuration, got #{adapters.inspect}"
    end
  end

  let(:conn) { Sequel.connect(uri) }

  before do
    %i(tasks users).each { |t| conn.drop_table?(t) }
  end

  with_adapters do
    let(:rom) do
      ROM.container(:sql, conn) do |conf|
        conf.default.create_table(:users) do
          primary_key :id
          column :last_name, String, null: false
          column :first_name, String, null: false
          column :email, String, null: false
          column :created_at, Time, null: false
          column :updated_at, Time, null: false
          column :age, Integer
        end

        conf.default.create_table(:tasks) do
          primary_key :id
          foreign_key :user_id, :users
          column :title, String, null: false
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations do
              belongs_to :users, as: :user
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
        user2 = factories[:user]

        expect(user1.created_at.class).to eq(Time)
        expect(user1.updated_at.class).to eq(Time)

        expect(user2.created_at).not_to eq(user1.created_at)
        expect(user2.updated_at).not_to eq(user1.updated_at)
      end
    end

    context 'traits' do
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
        expect(john.email).to eql('john@doe.org')
      end
    end

    context 'faker' do
      it 'exposes faker API in the DSL' do
        factories.define(:user) do |f|
          f.first_name { fake(:name, :first_name) }
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

    context 'using builders within callable blocks' do
      it 'exposes "create" method in callable attribute blocks' do
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
      it 'exposes "create" method in callable attribute blocks' do
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

        task = factories[:task]

        expect(task.title).to eql('A task')
        expect(task.user_id).to_not be(nil)
      end
    end
  end

  context 'without PK', :postgres do
    let(:rom) do
      ROM.container(:sql, conn) do |conf|
        conf.default.create_table(:users) do
          column :id, Integer, default: 1
          column :first_name, String, null: false
        end

        conf.relation(:users) do
          schema(infer: true) do
            attribute :id, ROM::SQL::Types::Serial
          end
        end
      end
    end

    it "works even if the table doesn't have a PK" do
      factories.define(:user) do |f|
        f.first_name 'Jane'
      end

      user = factories[:user]

      expect(user.id).to be(1)
      expect(user.first_name).to eql('Jane')
    end
  end

  context 'input schema', :postgres do |f|
    let(:rom) do
      ROM.container(:sql, conn) do |conf|
        conf.default.create_table(:users) do
          column :id, Integer, default: 1
          column :first_name, String, null: false
        end

        conf.relation(:users) do
          schema(infer: true) do
            attribute :id, ROM::SQL::Types::Serial
            attribute :first_name, ROM::SQL::Types::String.constructor(&:upcase)
          end
        end
      end
    end

    it 'uses input schema' do
      factories.define(:user) do |f|
        f.first_name 'Jane'
      end

      user = factories[:user, first_name: 'John']

      expect(user.id).to be(1)
      expect(user.first_name).to eql('JOHN')
      expect(rom.relation(:users).one[:first_name]).to eql('JOHN')
    end
  end
end
