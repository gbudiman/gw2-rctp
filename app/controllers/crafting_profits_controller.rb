class CraftingProfitsController < ApplicationController
	def list
		@list = CraftingProfit.all(order: 'crafting_profit_on_buy DESC')
		@count = CraftingProfit.count
	end
end
