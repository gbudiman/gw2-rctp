class RecipeBuilder
	attr_accessor :items, :recipes
	def initialize _r, _i
		@recipes = Array.new
		@items = Hash.new

		_i.each do |data|
			@items[data['ID']] = {
				name: 				data['Name'],
				item_type_id:		enumerate_type(data),
				rarity: 			data['Rarity'],
				description: 		data['Description'],
				tp_id: 				data['DataID'],
			}
		end

		_r.each do |data|
			data['Ingredients'].each do |ingredient|
				@recipes.push({
					discipline_level:	data['Rating'],
					discipline_id:		data['Type'],
					created_item_amount:data['Count'],
					created_item_id: 	data['CreatedItemId'],
					recipe_required: 	
						data['RequiresRecipeItem'] == 'true' ? 1 : 0,
					recipe_amount: 		ingredient['Count'],
					recipe_item_id: 	ingredient['ItemID'],
				})
			end
		end
	end

	private
		def enumerate_type _data
			case _data['Type']
			when 1 then return 1			# trophy = 0
			when 5 then return 2			# gizmo
			when 7 then return 3			# crafting material
			when 8 then return 4			# container
			when 9 then return 5			# upgrade component
			when 10 then return 6 			# minipet
			when 11	then return 7			# bag
			when 12	then return 8			# back
			when 13	then return 9			# trait guide
			when 15	then return 10			# tool
			when 16 then return 11			# minideck
			when 2							# weapon = 100 - 199
				return 100 + _data['WeaponType']
			when 3							# armor = 200 - 299
				return 200 +
					10 * _data['ArmorType'] + 
					_data['ArmorWeightType']
			when 4							# consumable = 800 - 899
				return 800 + _data['ConsumableType']
			when 6							# trinket = 900 - 909
				return 900 + _data['TrinketType']
			when 14							# gathering = 910 - 919
				return 910 + _data['GatheringType']
			else return 999					# unspecified type
			end
		end
end