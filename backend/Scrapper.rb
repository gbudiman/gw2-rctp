require 'mechanize'
require 'net/http'
require 'json'
require_relative 'Extern.rb'

class Scrapper
	def initialize
		@mechanize = Mechanize.new
		@scrap_result = Hash.new
		@extern = Extern.new
		@@gw2_login_page = 'https://account.guildwars2.com/login'
		@@gw2_authentication_page = 
			'https://tradingpost-live.ncplatform.net/authenticate'
		@@gw2_search_string = 
			'https://tradingpost-live.ncplatform.net/ws/search.json?count=0'
		@last_access = nil
	end

	def login _site
		case _site
		when :gw2
			@mechanize.get @@gw2_login_page do |page|
				page.form_with do |form|
					form.email = @extern.get :email
					form.password = @extern.get :password
				end.click_button

				break
			end
		when :gw2db
		end

		@last_access = _site

		return self
	end

	def scrap_data _site = @last_access
		case _site
		when :gw2
			@mechanize.get @@gw2_authentication_page
			@scrap_result[_site] = JSON.parse(
				@mechanize.get(@@gw2_search_string).body)
		when :gw2db
			@scrap_result[_site] = JSON.parse(
				@mechanize.get(@extern.get :gw2db_api).body)
		end
	end
end
