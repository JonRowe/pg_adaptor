require 'pg_adaptor'

RSpec.describe 'adapting structs into pg' do
  let(:db) { Sequel.postgres 'pg_adaptor_test'  }

  before do
    PGAdaptor.db = db
    db.extension :pg_array
    db.extension :pg_json
    db.create_table :test_table do
      primary_key :id
      String :name
      String :other
      column :members, "text[]"
      column :info, "jsonb"
      String :old_data # used to demo only fields specified inserted
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
    let(:klass)      { Struct.new :name, :other, :members, :info, :id }
    let(:adaptor)    { PGAdaptor.new :test_table, klass }
    let(:table)      { db[:test_table] }

    describe 'with a new model' do
      let(:model) { klass.new 'Test Model','Some Data',['Some Members'],{ some: :info }  }
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
          expect(data[:info]).to eq "some" => "info"
        end
      end

      context 'inserting' do
        let(:perform) { adaptor.insert model }
        it_should_behave_like 'new model'
      end

      context 'upserting' do
        let(:perform) { adaptor.upsert model }
        it_should_behave_like 'new model'
      end
    end

    describe 'with an existing model' do
      let(:model) { klass.new 'Test Model','Some Data',['Some Other Members'], { some: :info } }
      let(:id)    { table.insert(name: 'My Model', other: 'Some Value', members: Sequel.pg_array(['Some Members']), info: Sequel.pg_jsonb({other: :info})) }
      before do
        model.id = id
      end

      shared_examples_for 'modifying an existing model' do
        let(:data) { table.order(:id).last }

        it 'doesnt change the number of items in the table' do
          expect { perform }.to change { table.count }.by(0)
        end
        it 'sets my fields and values' do
          perform
          expect(data[:id]).to eq model.id
          expect(data[:name]).to  eq 'Test Model'
          expect(data[:other]).to eq 'Some Data'
          expect(data[:members]).to eq ['Some Other Members']
          expect(data[:info]).to eq "some" => "info"
        end
      end

      describe 'to update it' do
        let(:perform) { adaptor.update model }
        it_should_behave_like 'modifying an existing model'
      end

      describe 'to upsert it' do
        let(:perform) { adaptor.upsert model }
        it_should_behave_like 'modifying an existing model'
      end

      describe 'to fetch it' do
        let(:result) { adaptor.fetch(id: id) }

        it "returns a class" do
          expect(result).to be_a klass
        end
        specify "the classes fields are set correctly" do
          expect(result.id).to      eq id
          expect(result.name).to    eq 'My Model'
          expect(result.other).to   eq 'Some Value'
          expect(result.members).to eq ['Some Members']
        end
      end

      describe 'to remove it' do
        it 'removes the record matching the selector' do
          expect {
            adaptor.remove(id: id)
          }.to change { table.count }.to 0
        end
      end
    end

    describe 'finding multiples' do
      before do
        3.times do |i|
          table.insert(name: 'My Model', other: i)
        end
        3.times do |i|
          table.insert(name: 'Other Model', other: i)
        end
      end

      let(:result) { adaptor.find(name: 'My Model') }

      it 'returns 3 models' do
        expect(result.count).to eq 3
      end
      it 'translates all to klass' do
        expect(result.all? { |k| k.is_a? klass }).to be true
      end
      it 'gets them all' do
        expect(result.map(&:other)).to eq ['0', '1', '2']
      end
    end
  end
end
