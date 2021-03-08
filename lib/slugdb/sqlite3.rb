# frozen_string_literal: true

require 'sqlite3'
require_relative 'sqlite3/version'

class SlugDB
  ##
  # SlugDB backed by SQLite3
  class SQLite3
    def initialize(file) # rubocop:disable Metrics/MethodLength
      @sdb = ::SQLite3::Database.new(file)
      @sdb.execute(
        <<~SQL
          CREATE TABLE IF NOT EXISTS main(
            pk varchar(2048) NOT NULL,
            sk varchar(1024) NOT NULL,
            item varchar(409600) NOT NULL,
            PRIMARY KEY(pk, sk)
          )
        SQL
      )
      @sdb.execute(
        <<~SQL
          CREATE TABLE IF NOT EXISTS indexes(
            name varchar(255) NOT NULL,
            schema varchar(4096) NOT NULL,
            PRIMARY KEY(name)
          )
        SQL
      )
    end

    def list_partitions
      @sdb.execute('SELECT pk FROM main').map(&:first).uniq
    end

    def list_indexes
      @sdb.execute('SELECT * FROM indexes')
          .reduce({}) { |memo, (name, schema)| memo.merge(name => to_item(schema)) }
    end

    def add_index(name:, pk:, sk:, reindex: false) # rubocop:disable Metrics/MethodLength,Naming/MethodParameterName
      index = { name => { pk: pk, sk: sk } }

      if @sdb.execute('SELECT name FROM indexes WHERE name = ?', name).empty?
        @sdb.execute(
          <<~SQL
            CREATE TABLE IF NOT EXISTS index_#{name}(
              ipk varchar(2048) NOT NULL,
              isk varchar(1024) NOT NULL,
              pk varchar(2048) NOT NULL,
              sk varchar(1024) NOT NULL,
              item varchar(409600) NOT NULL,
              PRIMARY KEY(ipk, isk, pk, sk)
            )
          SQL
        )
        @sdb.execute(
          'INSERT INTO indexes (name, schema) VALUES (?, ?)',
          [name, to_raw(pk: pk, sk: sk)]
        )
      end

      reindex!(index) if reindex

      index
    end

    def reindex!(index)
      @sdb.execute('SELECT item FROM main').each do |raw_item,|
        item = to_item(raw_item)
        @sdb.execute('BEGIN TRANSACTION')
        index_delete_statements(index, item).each { |s, v| @sdb.execute(s, v) }
        index_insert_statements(index, item, raw_item).each { |s, v| @sdb.execute(s, v) }
        @sdb.execute('COMMIT TRANSACTION')
      end
    rescue ::SQLite3::SQLException => e
      @sdb.execute('ABORT TRANSACTION')
      raise e
    end

    def get_item(pk:, sk:, **_) # rubocop:disable Naming/MethodParameterName
      @sdb.execute(
        'SELECT item FROM main WHERE pk = ? AND sk = ?',
        [pk, sk]
      ).flatten.map(&method(:to_item)).first
    end

    def put_item(pk:, sk:, **attributes) # rubocop:disable Metrics/AbcSize,Naming/MethodParameterName
      new_item = attributes.merge(pk: pk, sk: sk)
      raw_item = to_raw(new_item)
      old_item = get_item(**new_item)
      indexes = list_indexes

      @sdb.execute('BEGIN TRANSACTION')
      @sdb.execute('DELETE FROM main WHERE pk = ? AND sk = ?', [pk, sk])
      index_delete_statements(indexes, old_item).each { |s, v| @sdb.execute(s, v) }
      index_insert_statements(indexes, new_item, raw_item).each { |s, v| @sdb.execute(s, v) }
      @sdb.execute('INSERT INTO main (pk, sk, item) VALUES (?, ?, ?)', [pk, sk, raw_item])
      @sdb.execute('COMMIT TRANSACTION')

      new_item
    rescue SQLite3::SQLException => e
      @sdb.execute('ABORT TRANSACTION')
      raise e
    end

    def delete_item(pk:, sk:, **_) # rubocop:disable Naming/MethodParameterName
      item = get_item(pk: pk, sk: sk)
      return if item.nil?

      indexes = list_indexes
      @sdb.execute('BEGIN TRANSACTION')
      @sdb.execute('DELETE FROM main WHERE pk = ? AND sk = ?', [pk, sk])
      index_delete_statements(indexes, item).each { |s, v| @sdb.execute(s, v) }
      @sdb.execute('COMMIT TRANSACTION')

      item
    rescue SQLite3::SQLException => e
      @sdb.execute('ABORT TRANSACTION')
      raise e
    end

    def query(pk:, index: 'main', select: nil, filter: nil) # rubocop:disable Naming/MethodParameterName
      results =
        if index == 'main'
          raw_query('SELECT sk, item FROM main WHERE pk = ?', [pk])
        else
          raw_query("SELECT isk, item FROM index_#{index} WHERE ipk = ?", [pk])
        end

      results = results.select { |sk,| select[sk] } if select
      results = results.filter { |_, item| filter[item] } if filter

      results.map(&:last)
    end

    private

    def to_raw(item)
      Marshal.dump(item)
    end

    def to_item(raw)
      Marshal.load(raw) # rubocop:disable Security/MarshalLoad
    end

    def index_delete_statements(indexes, item)
      indexes.map do |name, schema|
        next if item.nil?

        [
          "DELETE FROM index_#{name} WHERE #{schema[:pk]} = ? AND #{schema[:sk]} = ?",
          [item[schema[:pk]], item[schema[:sk]]]
        ]
      end.compact
    end

    def index_insert_statements(indexes, item, raw_item)
      indexes.map do |name, schema|
        next unless item.key?(schema[:pk]) && item.key?(schema[:sk])

        [
          "INSERT INTO index_#{name} (ipk, isk, pk, sk, item) VALUES(?, ?, ?, ?, ?)",
          [item[schema[:pk]], item[schema[:sk]], item[:pk], item[:sk], raw_item]
        ]
      end.compact
    end

    def raw_query(statement, values)
      return enum_for(:raw_query, statement, values) unless block_given?

      @sdb.execute(statement, values).each { |sk, raw_item| yield [sk, to_item(raw_item)] }
    end
  end
end
