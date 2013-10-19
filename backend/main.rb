require 'trollop'
require_relative 'Scrapper.rb'

scrapper = Scrapper.new
pp scrapper.login(:gw2).scrap_data
#pp scrapper.login(:gw2db).scrap_data