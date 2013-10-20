require 'sqlite3'

class Database
	def initialize
		@dbh = open_database
		@dbh.results_as_hash = true
		create_table
		prefill_table
	end

	def create_table
		@dbh.execute '
			CREATE TABLE IF NOT EXISTS crafting_profits(
				id INTEGER PRIMARY KEY
				, name TEXT
				, crafting_discipline TEXT
				, crafting_discipline_level INTEGER
				, sell_price INTEGER
				, sell_count INTEGER
				, buy_price INTEGER
				, buy_count INTEGER
				, crafting_cost INTEGER
				, crafting_profit_on_sell INTEGER
				, crafting_profit_on_buy INTEGER
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS disciplines(
				id INTEGER PRIMARY KEY
				, name TEXT
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS items(
				id INTEGER PRIMARY KEY
				, name TEXT
				, item_type_id INTEGER
				, rarity INTEGER
				, description TEXT
				, tp_id INTEGER
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS item_types(
				id INTEGER PRIMARY KEY
				, name TEXT
			)'

		@dbh.execute '
			CREATE TABLE IF NOT EXISTS markets(
				id INTEGER PRIMARY KEY
				, item_id INTEGER
				, time INTEGER
				, buy_count INTEGER
				, buy_price INTEGER
				, sell_count INTEGER
				, sell_price INTEGER
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

		@dbh.execute 'CREATE INDEX IF NOT EXISTS markets_time
						ON markets (time DESC)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS markets_id_time
						ON markets (item_id, time)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS cp_buy_profit
						ON crafting_profits (crafting_profit_on_buy)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS cp_sell_profit
						ON crafting_profits (crafting_profit_on_sell)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS cp_name
						ON crafting_profits (name)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS cp_discipline
						ON crafting_profits (
							crafting_discipline, crafting_discipline)'
		@dbh.execute 'CREATE UNIQUE INDEX IF NOT EXISTS items_tp_id
						ON items (tp_id)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS items_type
						ON items (item_type_id)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS items_rarity
						ON items (rarity)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS items_name
						ON items (name)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS recipe_discipline
						ON recipes (discipline_id, discipline_level)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS recipe_created_item_id
						ON recipes (created_item_id, recipe_required)'
		@dbh.execute 'CREATE INDEX IF NOT EXISTS recipe_recipe_item_id
						ON recipes (recipe_item_id, recipe_required)'
	end

	def get_all_craftables
		@dbh.execute '
			SELECT recipe_list.item_id
				, items.tp_id
				FROM
				(SELECT DISTINCT created_item_id AS item_id 
					FROM recipes
				UNION
				SELECT DISTINCT recipe_item_id AS item_id 
					FROM recipes)
				AS recipe_list
				INNER JOIN items
					ON recipe_list.item_id = items.id
			'
	end

	def open_database
		dbfile = File.dirname(__FILE__) + '/gw2-rctp.db'
		return SQLite3::Database.open dbfile
	end

	def truncate _table
		case _table
		when :items then table = 'items'
		when :markets then table = 'markets'
		when :recipes then table = 'recipes'
		end

		@dbh.execute "DELETE FROM #{table}"
	end

	def update_rows _table, _d = nil
		case _table
		when :crafting_profits
			@dbh.execute 'BEGIN TRANSACTION'
			@dbh.execute 'DELETE FROM crafting_profits'
			@dbh.execute '
				INSERT INTO crafting_profits (
					id
					, name
					, crafting_discipline
					, crafting_discipline_level
					, sell_price
					, sell_count
					, buy_price
					, buy_count
					, crafting_cost
					, crafting_profit_on_sell
					, crafting_profit_on_buy
				)
				SELECT crafting_tree.target_id AS target_id
					, target_item.name AS target_name
					, crafting_tree.discipline_name AS discipline_name
					, crafting_tree.discipline_level AS discipline_level
					, crafting_tree.target_sell_price AS target_sell_price
					, crafting_tree.target_sell_count AS target_sell_count
					, crafting_tree.target_buy_price AS target_buy_price
					, crafting_tree.target_buy_count AS target_buy_count
					, SUM(crafting_tree.crafting_cost) AS crafting_cost
					, CAST(crafting_tree.target_sell_price * 0.8 -
						SUM(crafting_tree.crafting_cost) AS integer)
						AS crafting_profit_on_sell
					, CAST(crafting_tree.target_buy_price * 0.8 -
						SUM(crafting_tree.crafting_cost) AS integer)
						AS crafting_profit_on_buy
					FROM
					(SELECT recipes.created_item_id AS target_id
						, recipes.recipe_amount * recipe_market.sell_price
							AS crafting_cost
						, disciplines.name AS discipline_name
						, recipes.discipline_level AS discipline_level
						, final_market.sell_price AS target_sell_price
						, final_market.sell_count AS target_sell_count
						, final_market.buy_price AS target_buy_price
						, final_market.buy_count AS target_buy_count
						FROM recipes
						INNER JOIN disciplines
							ON recipes.discipline_id = disciplines.id
						LEFT OUTER JOIN markets AS final_market
							ON final_market.item_id = recipes.created_item_id
								AND final_market.time =
									(SELECT MAX(time) from markets)
						LEFT OUTER JOIN markets AS recipe_market
							ON recipe_market.item_id = recipes.recipe_item_id
								AND final_market.time =
									(SELECT MAX(time) from markets)
					) AS crafting_tree
					INNER JOIN items AS target_item
						ON crafting_tree.target_id = target_item.id
					GROUP BY target_id
					ORDER BY target_buy_price - crafting_cost
				'
			@dbh.execute 'COMMIT TRANSACTION'
		when :items
			@dbh.execute 'BEGIN TRANSACTION'
			x = @dbh.prepare 'INSERT OR REPLACE INTO items (
						"id"
						, "name"
						, "item_type_id"
						, "rarity"
						, "description"
						, "tp_id"
					) VALUES(?, ?, ?, ?, ?, ?)'

			_d.each do |key, data|
				x.execute(key,
					data[:name],
					data[:item_type_id],
					data[:rarity],
					data[:description],
					data[:tp_id])
			end
			@dbh.execute 'COMMIT TRANSACTION'
		when :markets
			timestamp = Time.new.to_time.to_i
			@dbh.execute 'BEGIN TRANSACTION'
			x = @dbh.prepare "INSERT INTO markets (
					'item_id'
					, 'buy_count'
					, 'buy_price'
					, 'sell_count'
					, 'sell_price'
					, 'time'
				) VALUES(?, ?, ?, ?, ?, #{timestamp})"

			_d.each do |key, data|
				x.execute(key,
					data[:buy_count],
					data[:buy_price],
					data[:sell_count],
					data[:sell_price])
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
			disciplines = {
				1	=> 'Huntsman',
				2	=> 'Artificer',
				3	=> 'Weaponsmith',
				4	=> 'Armorsmith',
				5	=> 'Leatherworker',
				6	=> 'Tailor',
				7 	=> 'Jeweler',
				8 	=> 'Cook'
			}

			disciplines.each do |key, value|
				@dbh.execute "
					INSERT OR REPLACE INTO disciplines
					VALUES(#{key}, '#{value}')
					"
			end
		end
end