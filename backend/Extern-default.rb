class Extern

	def initialize

		@data = {

			:email		=> '', #Fill with your own identity and API GUID

			:password	=> '',

			:gw2db_api	=> '',

		}

	end



	def get _a

		return @data[_a]

	end

end
