class ItemBuffersController < ApplicationController
	def list_item_names
		@suggestions = Array.new
		ItemBuffer.select(:name).each do |item|
			@suggestions.push item.name
		end
		render json: @suggestions
	end	
end
