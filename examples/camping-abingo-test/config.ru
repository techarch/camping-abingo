gem 'camping' , '>= 2.0'
require 'active_record'
require 'rack'

gem 'markaby' , '>= 0.5'

require 'camping'
require 'camping/session'
require 'camping/reloader'

use_camping_reloader = true
if use_camping_reloader
	reloader = Camping::Reloader.new('camping-abingo-test.rb')
	#puts "reloader.apps=#{reloader.inspect}"
	app = reloader.apps[:CampingABingoTest]
else
	require 'camping-abingo-test.rb'
	app = Rack::Adapter::Camping.new(CampingABingoTest)
end
#---------------------------------------------

use Rack::Reloader

environment = ENV['DATABASE_URL'] ? 'production' : 'development'

run app		#from the command line: rackup config.ru -p 3301
