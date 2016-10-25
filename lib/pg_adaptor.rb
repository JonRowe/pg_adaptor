require 'sequel'
require 'json'
require "pg_adaptor/version"

class PGAdaptor
  class << self
    attr_accessor :db
  end

  def initialize name, klass
    @name = name
    @table = self.class.db[name.to_sym]
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

  def fetch selector = {}, *args
    build @table.where(selector, *args).first
  end

  def remove selector = {}
    @table.where(selector).delete
  end

  def find selector = {}, *args
    @table.where(selector, *args).map { |row| build row }
  end

private

  def build result
    return unless result
    @klass.new.tap do |model|
      @klass.members.each do |field|
        model[field] = result[field]
      end
    end
  end

  def schema
    @schema ||=
      begin
        schema = {}
        self.class.db.schema(@name).each do |(key, info)|
          schema[key] = info
        end
        schema
      end
  end

  def process(model)
    fields = {}
    model.each_pair do |field,value|
      next if field == :id && value.nil?
      raise "Field not present in schema: #{field}" unless schema[field.to_sym]
      case schema[field.to_sym][:db_type]
      when "jsonb"  then fields[field] = Sequel.pg_jsonb value
      when /\[\]$/  then fields[field] = Sequel.pg_array value
      else
        fields[field] = value
      end
    end
    fields
  end

end
