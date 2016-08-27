require 'spec_helper'
require 'ostruct'


RSpec.describe RomFactory::Builder do
  let!(:container)  {
    ROM.container(:sql, 'sqlite::memory') do |conf|
      conf.default.create_table(:users) do
        primary_key :id
        column :last_name, String, null: false
        column :first_name, String, null: false
        column :email, String, null: false
        column :created_at, Time, null: false
        column :updated_at, Time, null: false
      end
      conf.relation(:users) do
        schema(:users, infer: true) do

        end
      end
    end
  }

  before(:all) do
    class MappedUser
      def self.call(attrs)
        OpenStruct.new(attrs)
      end
    end

    RepoClass = Class.new(ROM::Repository[:users]) do
      commands :create
    end
  end

  describe "factory builder DSL" do
    it "does not error when trying using proper DSL" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_1) do
          first_name "Janis"
          last_name "Miezitis"
          email "janjiss@gmail.com"
        end
      end
    end

    it "Raises an error if arguments are not part of schema" do
      expect {
        RomFactory::Builder.define(container) do
          factory(repo: RepoClass, name: :user_2) do
            boobly "Janis"
          end
        end
      }.to raise_error(NoMethodError)
    end
  end

  context "creation of records" do
    it "creates a record based on defined factory" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_3) do
          first_name "Janis"
          last_name "Miezitis"
          email "janjiss@gmail.com"
          created_at Time.now
          updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_3)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end

    it "supports callable values" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_4) do
          first_name "Janis"
          last_name "Miezitis"
          email "janjiss@gmail.com"
          created_at {Time.now}
          updated_at {Time.now}
        end
      end

      user = RomFactory::Builder.create(:user_4)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
      expect(user.created_at).not_to be_nil
      expect(user.updated_at).not_to be_nil
    end
  end

  context "mapping of the records" do
    it "creates a record based on defined factory" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_6, as: MappedUser) do
          first_name "Janis"
          last_name "Miezitis"
          email "janjiss@gmail.com"
          created_at Time.now
          updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_6)
      expect(user).to be_kind_of(OpenStruct)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end
  end

  context "changing values" do
    it "supports overwriting of values" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_7, as: MappedUser) do
          first_name "Janis"
          last_name "Miezitis"
          email "janjiss@gmail.com"
          created_at Time.now
          updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_7, email: "holla@gmail.com")
      expect(user.email).to eq("holla@gmail.com")
    end
  end

  context "errors" do
    it "raises error if factory with the same name is registered" do
      RomFactory::Builder.define(container) do
        factory(repo: RepoClass, name: :user_8) do
        end
      end

      expect {
        RomFactory::Builder.define do
          factory(repo: RepoClass, name: :user_8) do
          end
        end
      }.to raise_error(ArgumentError)
    end
  end
end
