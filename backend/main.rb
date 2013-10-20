require 'trollop'
require_relative 'Database.rb'
require_relative 'RecipeBuilder.rb'
require_relative 'Scrapper.rb'

opts = Trollop::options do
	opt :scrap_market, 'Scrap market data', short: 'm'
	opt :scrap_recipe, 'Scrap recipe data', short: 'r'
end

scrapper = Scrapper.new

scrapper.login_to(:gw2).scrap_data if opts[:scrap_market]

if opts[:scrap_recipe]
	database = Database.new
	recipe = RecipeBuilder.new(
		scrapper.login_to(:gw2db).scrap_data(:gw2db_recipes),
		scrapper.login_to(:gw2db).scrap_data(:gw2db_items))
	
	database.update_rows(:items, recipe.items)
	database.update_rows(:recipes, recipe.recipes)
end