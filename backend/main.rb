require 'trollop'
require_relative 'Database.rb'
require_relative 'MarketSentinel.rb'
require_relative 'RecipeBuilder.rb'
require_relative 'Scrapper.rb'

opts = Trollop::options do
	opt :scrap_market, 'Scrap market data', short: 'm'
	opt :scrap_recipe, 'Scrap recipe data', short: 'r'
	opt :truncate_items, 'Truncate item data'
	opt :truncate_markets, 'Truncate market data'
	opt :truncate_recipes, 'Truncate recipe data'
end

scrapper = Scrapper.new
database = Database.new

database.truncate :items if opts[:truncate_items]
database.truncate :markets if opts[:truncate_markets]
database.truncate :recipes if opts[:truncate_recipes]

if opts[:scrap_market]
	market = MarketSentinel.new(
		database.get_all_craftables,
		scrapper.login_to(:gw2).scrap_data)
	
	database.update_rows(:markets, market.price_data)
	database.update_rows(:crafting_profits)
end

if opts[:scrap_recipe]
	recipe = RecipeBuilder.new(
		scrapper.login_to(:gw2db).scrap_data(:gw2db_recipes),
		scrapper.login_to(:gw2db).scrap_data(:gw2db_items))
	
	database.update_rows(:items, recipe.items)
	database.update_rows(:recipes, recipe.recipes)
end