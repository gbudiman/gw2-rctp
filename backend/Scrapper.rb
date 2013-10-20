require 'mechanize'
require 'net/http'
require 'json'
require_relative 'Extern.rb'

class Scrapper
	attr_accessor :scrap_result

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

	def login_to _site
		case _site
		when :gw2
			@mechanize.get @@gw2_login_page do |page|
				page.form_with do |form|
					form.email = @extern.get :email
					form.password = @extern.get :password
				end.click_button

				break
			end
		end

		@last_access = _site

		return self
	end

	def scrap_data _site = @last_access
		case @last_access
		when :gw2
			@mechanize.get @@gw2_authentication_page
			@scrap_result[_site] = JSON.parse(
				@mechanize.get(@@gw2_search_string).body)['results']
		when :gw2db
			@scrap_result[_site] = JSON.parse(
				@mechanize.get(@extern.get _site).body)
		end
	end
end
