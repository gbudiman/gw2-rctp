class MarketSentinel
	attr_accessor :price_data
	def initialize _r, _m
		@market_data = Hash.new
		@price_data = Hash.new

		_m.each do |data|
			@market_data[data['data_id'].to_i] = {
				buy_price: 		data['buy_price'].to_i,
				buy_count: 		data['buy_count'].to_i,
				sell_price: 	data['sell_price'].to_i,
				sell_count: 	data['sell_count'].to_i,
			}
		end

		_r.each do |data|
			m = @market_data[data['tp_id']]
			next if m == nil
			@price_data[data['item_id']] = {
				buy_price: 		m[:buy_price],
				buy_count: 		m[:buy_count],
				sell_price: 	m[:sell_price],
				sell_count: 	m[:sell_count],
			}
		end
	end
end