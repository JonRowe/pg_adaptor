require 'pg_adaptor'

RSpec.describe 'adapting structs into pg' do
  let(:db) { Sequel.postgres 'pg_adaptor_test'  }

  before do
    PGAdaptor.db = db
    db.extension :pg_array
    db.create_table :test_table do
      primary_key :id
      String :name
      String :other
      column :members, "text[]"
    end
  end

  after do
    db.drop_table :test_table
  end

  describe 'db setup' do
    it 'can be configured' do
      PGAdaptor.db = fake = double
      expect(PGAdaptor.db).to eq fake
    end
  end

  describe 'using the adaptor' do
    let(:klass)      { Struct.new :name, :other, :members, :id }
    let(:adaptor)    { PGAdaptor.new :test_table, klass }
    let(:table)      { db[:test_table] }

    describe 'with a new model' do
      let(:model) { klass.new 'Test Model','Some Data',['Some Members'],'fake key'  }
      let(:data)  { table.order(:id).last }

      shared_examples_for 'creates a record' do
        it 'changes the number of items in the table' do
          expect { perform }.to change { table.count }.by(1)
        end
        it 'generates an id, ignoring any set key' do
          perform
          expect(data[:id]).to be_a Integer
        end
      end

      shared_examples_for 'new model' do
        it_should_behave_like 'creates a record'
        it 'sets my fields and values' do
          perform
          expect(data[:name]).to  eq 'Test Model'
          expect(data[:other]).to eq 'Some Data'
          expect(data[:members]).to eq ['Some Members']
        end
      end

      context 'inserting' do
        let(:perform) { adaptor.insert model }
        it_should_behave_like 'new model'
      end
    end
  end
end
