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

  def upsert model, opts = { field: :id }
    values = process model
    @table.insert_conflict(target: opts[:field], update: values).insert values
  end

  def update model, query = { id: model.id }
    @table.where(query).update process(model)
  end

  def fetch selector = {}, opts = {}
    build @table.where(selector).first
  end

  def remove selector = {}
    @table.where(selector).delete
  end

  def find selector = {}
    @table.where(selector).map { |row| build row }
  end

private

  def build result
    @klass.new.tap do |model|
      result.each { |field,value| model[field] = value }
    end
  end

  def process(model)
    fields = {}
    model.each_pair do |field,value|
      next if field == :id && value.nil?
      if Array === value
        fields[field] = Sequel.pg_array value
      else
        fields[field] = value
      end
    end
    fields
  end

end
