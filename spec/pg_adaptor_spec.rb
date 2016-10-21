require 'pg_adaptor'

RSpec.describe 'adapting structs into pg' do

  describe 'db setup' do
    it 'can be configured' do
      PGAdaptor.db = fake = double
      expect(PGAdaptor.db).to eq fake
    end
  end

end
