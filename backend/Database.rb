require 'sqlite3'

class Database
	def initialize
		@dbh = open_database
		@dbh.results_as_hash = true
		create_table
	end

	def create_table
		@dbh.execute '
			CREATE TABLE IF NOT EXISTS items(
				id INTEGER PRIMARY KEY
				, name TEXT
				, item_type_id INTEGER
				, rarity INTEGER
				, description TEXT
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS item_types(
				id INTEGER PRIMARY KEY
				, name TEXT
			)'
		@dbh.execute '
			CREATE TABLE IF NOT EXISTS recipes(
				id INTEGER PRIMARY KEY
				, discipline_id INTEGER
				, discipline_level INTEGER
				, created_item_id INTEGER
				, created_item_amount INTEGER
				, recipe_item_id INTEGER
				, recipe_amount INTEGER
				, recipe_required INTEGER
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS recipe_types(
				id INTEGER PRIMARY KEY
				, discipline_name TEXT
			)'
	end

	def open_database
		dbfile = File.dirname(__FILE__) + '/gw2-rctp.db'
		return SQLite3::Database.open dbfile
	end

	def update_rows _table, _d
		case _table
		when :items
			@dbh.execute 'BEGIN TRANSACTION'
			x = @dbh.prepare 'INSERT OR REPLACE INTO items VALUES(
					?, ?, ?, ?, ?)'

			_d.each do |key, data|
				x.execute(key,
					data[:name],
					data[:item_type],
					data[:rarity],
					data[:description])
			end
			@dbh.execute 'COMMIT TRANSACTION'
		when :recipes
			@dbh.execute 'BEGIN TRANSACTION'
			@dbh.execute 'DELETE FROM recipes'
			x = @dbh.prepare 'INSERT OR REPLACE INTO recipes (
						"discipline_id"
						, "discipline_level"
						, "created_item_id"
						, "created_item_amount"
						, "recipe_item_id"
						, "recipe_amount"
						, "recipe_required"
					) VALUES(?, ?, ?, ?, ?, ?, ?)'

			_d.each do |e|
				x.execute(e[:discipline_id],
					e[:discipline_level],
					e[:created_item_id],
					e[:created_item_amount],
					e[:recipe_item_id],
					e[:recipe_amount],
					e[:recipe_required])
			end
			@dbh.execute 'COMMIT TRANSACTION'
		end
	end

	private
		def prefill_table
		end
end