require 'sequel'
require "pg_adaptor/version"

class PGAdaptor
  class << self
    attr_accessor :db
  end

  def initialize name, klass
    @table = self.class.db[name]
    @klass = klass
  end

  def insert model
    @table.insert process(model)
  end

private

  def process(model)
    fields = {}
    model.each_pair do |field,value|
      next if field == :id
      if Array === value
        fields[field] = Sequel.pg_array value
      else
        fields[field] = value
      end
    end
    fields
  end

end
