=begin rdoc

[Abingo|identity|flip();test();bingo!(){bg:red}]
[Experiment|test_name;status|start_experiment!();end_experiment!(){bg:green}]
[Alternative|content;lookup;weight;participants;conversions|score_conversion();score_participation(){bg:yellow}]
[User|id;username{bg:blue}]
[Abingo]uses -.->[Experiment]
[Abingo]-id>[User]
[Experiment]++1-alternatives >*[Alternative]


Author::	Philippe F. Monnet (mailto:pfmonnet@gmail.com)
Copyright:: Copyright (c) 2010 Philippe F. Monnet - ABingo Camping plugin
Copyright:: Copyright (c) 2009 Patrick McKenzie - A subset of the Rails ABingo plugin reused in  ABingo Camping
License::   Distributes under the same terms as Ruby
Version:: 1.0.3

:main: ABingoCampingPlugin

=Installing Camping-ABingo
A lightweight ABingo plugin for Ruby Camping. 
To install the library and its prerequisisites, type the following command(s):

  $ gem install camping-abingo

=Adding ABingo Provider Support To Your App


===Add new gem and require statements
Add the following statements towards the top of your source file (before the Camping.goes statement):

	gem 'camping' , '>= 2.0'	
	gem 'filtering_camping' , '>= 1.0'	

	%w(rubygems active_record erb  fileutils json markaby md5 redcloth  
	camping camping/session filtering_camping camping-abingo
	).each { |lib| require lib }

===Customizing the main module

First we'll make sure to include the Camping::Session and CampingFilters modules, and to extend the app module with ABingoCampingPlugin, like so:

	module CampingABingoTest
		include Camping::Session
		include CampingFilters

		extend  ABingoCampingPlugin
		include ABingoCampingPlugin::Filters
		
		# ...
	end

This gives us the ability to leverage a logger for the camping-abingo plugin.

	app_logger = Logger.new(File.dirname(__FILE__) + '/camping-abingo-test.log')
	app_logger.level = Logger::DEBUG
	Camping::Models::Base.logger = app_logger
	ABingoCampingPlugin.logger   = app_logger

Now let's customize the create method by adding a call to ABingoCampingPlugin.create, so we can give the plugin to run any needed initialization
(such as running the ABingo-specific ActiveRecord migration).

	def CampingABingoTest.create
		ABingoCampingPlugin.create
	end

Also if you plan on using the ABingo dashboard to view the statistics, you need to define the user id associated with the administrator:

		Abingo.options[:abingo_administrator_user_id] = 1 #change this id to match the account id you need
	
Ok, at this point we have a minimally configured application module. Our next step is to move on to the Models module.

===Plugging in the ABingo models

First, we'll include the include ABingoCampingPlugin::Models module so we can get all the ABingo-specific models. Then we'll define a User model. The User will need to keep track of the applications it provided access to. It will also manage the tokens associated with these applications. Our model will look like this:

	class User < Base;
		has_many :client_applications
		has_many :tokens, 
			:class_name=>"OauthToken",
			:order=>"authorized_at desc",
			:include=>[:client_application]

	end

Now we need a CreateUserSchema migration class to define our database tables for User, and ABingo models. In the up and down methods we will plugin a call to the corresponding method from the ABingoCampingPlugin::Models module to create the tables for the Experiment and Alternative models.

	class CreateUserSchema < V 1.0
		def self.up
			create_table :CampingABingoTest_users, :force => true do |t|
				t.integer 	:id, :null => false
				t.string		:username
				t.string		:password
			end
			
			User.create :username => 'admin', :password => 'camping'
			
			ABingoCampingPlugin::Models.up
		end
		
		def self.down		
			ABingoCampingPlugin::Models.down
			
			drop_table :CampingABingoTest_users
		end
	end

At this point we can go back to the main module and add the code to configure the ActiveRecord connection and invoke our new schema migration if the User table does not exist yet. This code will be added to the create method:

	module CampingABingoTest
		# ...	

		def CampingABingoTest.create
			dbconfig = YAML.load(File.read('config/database.yml'))							
			Camping::Models::Base.establish_connection  dbconfig['development']		
			
			ABingoCampingPlugin.create
			Abingo.cache.logger = Camping::Models::Base.logger
			Abingo.options[:abingo_administrator_user_id] = 1
			
			CampingABingoTest::Models.create_schema :assume => (CampingABingoTest::Models::User.table_exists? ? 1.1 : 0.0)
		end
	end

You probably noticed that the database configuration is loaded from a database.yml file. So let's create a subfolder named config and a file named database.yml, then let's configure the yaml file as follows:

	development:
	  adapter: sqlite3
	  database: camping-abingo-test.db

Now if we restart the application, our migration should be executed.  
  
===Creating a common helpers module

The Helpers module is used in Camping to provide common utilities to both the Controllers and Views modules. Enhancing our Helpers module is very easy, we need to add both and extend and an include of the ABingoCampingPlugin::Helpers module so we can enhance both instance and class sides:

	module CampingABingoTest::Helpers
		extend ABingoCampingPlugin::Helpers
		include ABingoCampingPlugin::Helpers
	end

===Plugging in the ABingo controllers

We will need to extend our app Controllers module with the ABingoCampingPlugin::Controllers  module using the extend statement. Then just before the end of the Controllers module, we'll add a call to the include_abingo_controllers  method. This is how camping-abingo will inject and plugin the common ABingo controllers and helpers. It is important that this call always remain the last statement of the module, even when you add new controller classes. So the module should look like so:

	module CampingABingoTest::Controllers
		extend ABingoCampingPlugin::Controllers

		# ...

		include_abingo_controllers
	end #Controllers

Before we continue fleshing out the logic of our controllers, let's finish hooking up the Views module.
			
===Plugging in the ABingo common views

We will need to extend our app Views module with the ABingoCampingPlugin::Views  module using the extend statement. Then just before the end of the Views module, we'll add a call to the include_abingo_views method. This is how camping-abingo will inject and plugin the common ABingo views. It is important that this call always remain the last statement of the module, even when you add new view methods. So the module should look like so:

	module CampingABingoTest::Views
		extend ABingoCampingPlugin::Views

		# ...
		
		include_abingo_views
	end


==Testing And Troubleshooting

At this stage, we have a basic Camping ABingo Tester, now let's test it! 
Run:
	camping --port 3301 camping-abingo-test.rb

The migrations for both our test app and the plugin will be run. So at this point you should see 3 tables:
- abingo_alternatives
- abingo_experiments
- CampingABingoTest_users
   
=== Test App

I suggest you test the app using FireFox with the Firebug and Firecookie activated. This will make troubleshooting much easier.
	
Navigate to:
	http://localhost:3301/

Notice in the Debugging Information panel of the page that Abingo assigned a state variable named abingo_identity with a random value.
Click on the "XYZ SAAS Application Landing page variations" link. This page contains 2 variable content areas:
- The "special_promo" div content
- The "signup_btn" button text

Abingo will randomly select an alternative for each area.
Once you click on the sign up button, ABingo will track the conversion.

Now, using Firecookie, delete the campingabingotest.state cookie. And go back to the main page. Notice that the abingo_identity has changed.
You can repeat the scenario and probably will get different results.
  
=== Dashboard

If you had created a test account and logged in, the sign-out and sign back in as the administrator of the test app (admin/camping)/
You should now see an "ABingo Dashboard" option on the top navigation. Click on it or navigate to:
	http://localhost:3301/abingo/dashboard
	
You should see two experiments:
- Special Promo
- Call To Action

For each experiment you can see the various alternatives and their associated number of participants and conversions.There is also a summary of the experiment.
If you want to terminate an experiment click on the corresponding link in the far right column.
	
===Examples Source Code

Under the examples/camping-abingo-test you will find the full source for the CampingABingoTest app. 
	
=More information
Check for updates :
- http://blog.monnet-usa.com
- https://github.com/techarch/camping-abingo
=end

require 'active_record'

# Main Abingo class
#
class Abingo
  @@VERSION = "1.0.3"
  @@MAJOR_VERSION = "1.0"
  cattr_reader :VERSION
  cattr_reader :MAJOR_VERSION

  #Not strictly necessary, but eh, as long as I'm here.
  cattr_accessor :salt
  @@salt = "Not really necessary."

  @@options ||= {}
  cattr_accessor :options

  #Defined options:
  # :enable_specification  => if true, allow params[test_name] to override the calculated value for a test.
  # :enable_override_in_session => if true, allows session[test_name] to override the calculated value for a test.
  # :expires_in => if not nil, passes expire_in to creation of per-user cache keys.  Useful for Redis, to prevent expired sessions
  #               from running wild and consuming all of your memory.
  # :count_humans_only => Count only participation and conversions from humans.  Humans can be identified by calling Abingo.mark_human!
  #                       This can be done in e.g. Javascript code, which bots will typically not execute.  See FAQ for details.
  # :expires_in_for_bots => if not nil, passes expire_in to creation of per-user cache keys, but only for bots.
  #                         Only matters if :count_humans_only is on.
  # :abingo_administrator_user_id => the user account id of the ABingo administrator on the site
  #			This is used as a primitive mechanism to control access to the ABingo dashboard
  
  #ABingo stores whether a particular user has participated in a particular
  #experiment yet, and if so whether they converted, in the cache.
  #
  #It is STRONGLY recommended that you use a MemcacheStore for this.
  #If you'd like to persist this through a system restart or the like, you can
  #look into memcachedb, which speaks the memcached protocol.  From the perspective
  #of Rails it is just another MemcachedStore.
  #
  #You can overwrite Abingo's cache instance, if you would like it to not share
  #your generic Rails cache.
  cattr_writer :cache

  def self.cache
    @@cache || ActiveSupport::Cache.lookup_store(:memory_store) # Camping-specific change to explicitly request a cache store
  end
  
  #This method gives a unique identity to a user.  It can be absolutely anything
  #you want, as long as it is consistent.
  #
  #We use the identity to determine, deterministically, which alternative a user sees.
  #This means that if you use Abingo.identify_user on someone at login, they will
  #always see the same alternative for a particular test which is past the login
  #screen.  For details and usage notes, see the docs.
  def self.identity=(new_identity)
    @@identity = new_identity.to_s
  end

  def self.identity
    @@identity ||= rand(10 ** 10).to_i.to_s
  end

  #A simple convenience method for doing an A/B test.  Returns true or false.
  #If you pass it a block, it will bind the choice to the variable given to the block.
  def self.flip(test_name)
    if block_given?
      yield(self.test(test_name, [true, false]))
    else
      self.test(test_name, [true, false])
    end
  end

  #This is the meat of A/Bingo.
  #options accepts
  #  :multiple_participation (true or false)
  #  :conversion  name of conversion to listen for  (alias: conversion_name)
  def self.test(test_name, alternatives, options = {})
	ABingoCampingPlugin.logger.debug "test #{test_name} alternatives: #{alternatives.inspect} options:#{options.inspect} for #{Abingo.identity}"
    short_circuit = Abingo.cache.read("Abingo::Experiment::short_circuit(#{test_name})".gsub(" ", "_"))
    unless short_circuit.nil?
      return short_circuit  #Test has been stopped, pick canonical alternative.
    end
    
    unless ABingoCampingPlugin::Models::Experiment.exists?(test_name) # Camping-specific
      lock_key = "Abingo::lock_for_creation(#{test_name.gsub(" ", "_")})"
      creation_required = true

      #this prevents (most) repeated creations of experiments in high concurrency environments.
      if Abingo.cache.exist?(lock_key)
        creation_required = false
        while Abingo.cache.exist?(lock_key)
          sleep(0.1)
        end
        creation_required = ABingoCampingPlugin::Models::Experiment.exists?(test_name)	# Camping-specific
      end

      if creation_required
        Abingo.cache.write(lock_key, 1, :expires_in => 5.seconds)
        conversion_name = options[:conversion] || options[:conversion_name]
        ABingoCampingPlugin::Models::Experiment.start_experiment!(test_name, self.parse_alternatives(alternatives), conversion_name) # Camping-specific
        Abingo.cache.delete(lock_key)
      end
    end

    choice = self.find_alternative_for_user(test_name, alternatives)
    participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []
    
    #Set this user to participate in this experiment, and increment participants count.
    if options[:multiple_participation] || !(participating_tests.include?(test_name))
      unless participating_tests.include?(test_name)
        participating_tests = participating_tests + [test_name]
        expires_in = Abingo.expires_in
        if expires_in
          Abingo.cache.write("Abingo::participating_tests::#{Abingo.identity}", participating_tests, {:expires_in => expires_in})
        else
          Abingo.cache.write("Abingo::participating_tests::#{Abingo.identity}", participating_tests)
        end
      end
      #If we're only counting known humans, then postpone scoring participation until after we know the user is human.
      if (!@@options[:count_humans_only] || Abingo.is_human?)
        ABingoCampingPlugin::Models::Alternative.score_participation(test_name) # Camping-specific
      end
    end

    if block_given?
      yield(choice)
    else
      choice
    end
  end

  #Scores conversions for tests.
  #test_name_or_array supports three types of input:
  #
  #A conversion name: scores a conversion for any test the user is participating in which
  #  is listening to the specified conversion.
  #
  #A test name: scores a conversion for the named test if the user is participating in it.
  #
  #An array of either of the above: for each element of the array, process as above.
  #
  #nil: score a conversion for every test the u
  def Abingo.bingo!(name = nil, options = {})
    if name.kind_of? Array
      name.map do |single_test|
        self.bingo!(single_test, options)
      end
    else
      if name.nil?
        #Score all participating tests
        participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []
        participating_tests.each do |participating_test|
          self.bingo!(participating_test, options)
        end
      else #Could be a test name or conversion name.
        conversion_name = name.gsub(" ", "_")
        tests_listening_to_conversion = Abingo.cache.read("Abingo::tests_listening_to_conversion#{conversion_name}")
        if tests_listening_to_conversion
          if tests_listening_to_conversion.size > 1
            tests_listening_to_conversion.map do |individual_test|
              self.score_conversion!(individual_test.to_s)
            end
          elsif tests_listening_to_conversion.size == 1
            test_name_str = tests_listening_to_conversion.first.to_s
            self.score_conversion!(test_name_str)
          end
        else
          #No tests listening for this conversion.  Assume it is just a test name.
          test_name_str = name.to_s
          self.score_conversion!(test_name_str)
        end
      end
    end
  end

  def self.participating_tests(only_current = true)
    identity = Abingo.identity
    participating_tests = Abingo.cache.read("Abingo::participating_tests::#{identity}") || []
    tests_and_alternatives = participating_tests.inject({}) do |acc, test_name|
      alternatives_key = "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_")
      alternatives = Abingo.cache.read(alternatives_key)
      acc[test_name] = Abingo.find_alternative_for_user(test_name, alternatives)
      acc
    end
    if (only_current)
      tests_and_alternatives.reject! do |key, value|
        self.cache.read("Abingo::Experiment::short_circuit(#{key})")
      end
    end
    tests_and_alternatives
  end

  #Marks that this user is human.
  def self.human!
    Abingo.cache.fetch("Abingo::is_human(#{Abingo.identity})",  {:expires_in => Abingo.expires_in(true)}) do
      #Now that we know the user is human, score participation for all their tests.  (Further participation will *not* be lazy evaluated.)

      #Score all tests which have been deferred.
      participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []

      #Refresh cache expiry for this user to match that of known humans.
      if (@@options[:expires_in_for_bots] && !participating_tests.blank?)
        Abingo.cache.write("Abingo::participating_tests::#{Abingo.identity}", participating_tests, {:expires_in => Abingo.expires_in(true)})
      end
      
      participating_tests.each do |test_name|
        Alternative.score_participation(test_name)
        if conversions = Abingo.cache.read("Abingo::conversions(#{Abingo.identity},#{test_name}")
          conversions.times { Alternative.score_conversion(test_name) }
        end
      end
      true #Marks this user as human in the cache.
    end
  end

  protected

  def self.is_human?
    !!Abingo.cache.read("Abingo::is_human(#{Abingo.identity})")
  end

  #For programmer convenience, we allow you to specify what the alternatives for
  #an experiment are in a few ways.  Thus, we need to actually be able to handle
  #all of them.  We fire this parser very infrequently (once per test, typically)
  #so it can be as complicated as we want.
  #   Integer => a number 1 through N
  #   Range   => a number within the range
  #   Array   => an element of the array.
  #   Hash    => assumes a hash of something to int.  We pick one of the 
  #              somethings, weighted accorded to the ints provided.  e.g.
  #              {:a => 2, :b => 3} produces :a 40% of the time, :b 60%.
  #
  #Alternatives are always represented internally as an array.
  def self.parse_alternatives(alternatives)
    if alternatives.kind_of? Array
      return alternatives
    elsif alternatives.kind_of? Integer
      return (1..alternatives).to_a
    elsif alternatives.kind_of? Range
      return alternatives.to_a
    elsif alternatives.kind_of? Hash
      alternatives_array = []
      alternatives.each do |key, value|
        if value.kind_of? Integer
          alternatives_array += [key] * value
        else
          raise "You gave a hash with #{key} => #{value} as an element.  The value must be an integral weight."
        end
      end
      return alternatives_array
    else
      raise "I don't know how to turn [#{alternatives}] into an array of alternatives."
    end
  end

  def self.retrieve_alternatives(test_name, alternatives)
    cache_key = "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_")
    alternative_array = self.cache.fetch(cache_key) do
      self.parse_alternatives(alternatives)
    end
    alternative_array
  end

  def self.find_alternative_for_user(test_name, alternatives)
    alternatives_array = retrieve_alternatives(test_name, alternatives)
    selected_alternative = alternatives_array[self.modulo_choice(test_name, alternatives_array.size)]
	ABingoCampingPlugin.logger.debug "find_alternative_for_user(#{test_name}, #{alternatives}, #{self.identity}) > #{selected_alternative}"
	selected_alternative
  end

  #Quickly determines what alternative to show a given user.  Given a test name
  #and their identity, we hash them together (which, for MD5, provably introduces
  #enough entropy that we don't care) otherwise
  def self.modulo_choice(test_name, choices_count)
    Digest::MD5.hexdigest(Abingo.salt.to_s + test_name + self.identity.to_s).to_i(16) % choices_count
  end

  def self.score_conversion!(test_name)
    test_name.gsub!(" ", "_")
    participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []
 	ABingoCampingPlugin.logger.debug "score_conversion (#{test_name}) participating_tests=#{participating_tests.inspect} flag=#{participating_tests.include?(test_name)} options=#{options.inspect}"
	
    if options[:assume_participation] || participating_tests.include?(test_name)
      cache_key = "Abingo::conversions(#{Abingo.identity},#{test_name}"
	  ABingoCampingPlugin.logger.debug "score_conversion cache_key=#{cache_key}"
      if options[:multiple_conversions] || !Abingo.cache.read(cache_key)
	    ABingoCampingPlugin.logger.debug "score_conversion is human=#{!options[:count_humans_only] || Abingo.is_human?}"
        if !options[:count_humans_only] || Abingo.is_human?
          ABingoCampingPlugin::Models::Alternative.score_conversion(test_name) # Camping-specific
        end

        if Abingo.cache.exist?(cache_key)
		  ABingoCampingPlugin.logger.debug "score_conversion increment #{cache_key}"
          Abingo.cache.increment(cache_key)
        else
		  ABingoCampingPlugin.logger.debug "score_conversion write #{cache_key}"
          Abingo.cache.write(cache_key, 1)
        end
      end
    end
  end

  def self.expires_in(known_human = false)
    expires_in = nil
    if (@@options[:expires_in])
      expires_in = @@options[:expires_in]
    end
    if (@@options[:count_humans_only] && @@options[:expires_in_for_bots] && !(known_human || Abingo.is_human?))
      expires_in = @@options[:expires_in_for_bots]
    end
    expires_in
  end
  
 
end # Abingo class

# Main module for the ABingo Camping Plugin
#
module ABingoCampingPlugin
	@@logger = nil
	
	# Logger for the ABingoCampingPlugin - can be assigned the main logger for the main web app
	def self.logger
		@@logger
	end

	def self.logger=(a_logger)
		@@logger = a_logger
	end

	# Provides a hook to initialize the plugin in the context of the main web app module
	def self.create
		#Abingo.cache = ActiveSupport::Cache.lookup_store(:file_store, File.dirname(__FILE__) + "/cache")
		Abingo.cache = ActiveSupport::Cache.lookup_store(:memory_store)
	end		
end

# Helpers module for ABingo Camping Plugin.
# The module will be plugged in to the main app Helpers module. 
# Its methods will be added to Controllers and Views.
# Example:
# 	module CampingABingoTest::Helpers
#		extend ABingoCampingPlugin::Helpers
#		include ABingoCampingPlugin::Helpers
#	end 
#

module ABingoCampingPlugin::Helpers
	
	# Logs a specific message if in debug mode
	def log_debug(msg)
		ABingoCampingPlugin.logger.debug(msg)	if ABingoCampingPlugin.logger && ABingoCampingPlugin.logger.debug?
	end

	# Reverse engineers the main app module
	def app_module
		app_module_name = self.class.to_s.split("::").first	
		app_module = app_module_name.constantize	
	end
	
	# --- ConversionRate ------------------------------
	def conversion_rate
		1.0 * conversions / participants
	end

	def pretty_conversion_rate
		sprintf("%4.2f%%", conversion_rate * 100)
	end	
	
	# --- Statistics --------------------------
	HANDY_Z_SCORE_CHEATSHEET = [[0.10, 1.29], [0.05, 1.65], [0.01, 2.33], [0.001, 3.08]]

	PERCENTAGES = {0.10 => '90%', 0.05 => '95%', 0.01 => '99%', 0.001 => '99.9%'}

	DESCRIPTION_IN_WORDS = {0.10 => 'fairly confident', 0.05 => 'confident',
						 0.01 => 'very confident', 0.001 => 'extremely confident'}
	def zscore
		if alternatives.size != 2
		  raise "Sorry, can't currently automatically calculate statistics for A/B tests with > 2 alternatives."
		end

		if (alternatives[0].participants == 0) || (alternatives[1].participants == 0)
		  raise "Can't calculate the z score if either of the alternatives lacks participants."
		end

		cr1 = alternatives[0].conversion_rate
		cr2 = alternatives[1].conversion_rate

		n1 = alternatives[0].participants
		n2 = alternatives[1].participants

		numerator = cr1 - cr2
		frac1 = cr1 * (1 - cr1) / n1
		frac2 = cr2 * (1 - cr2) / n2

		numerator / ((frac1 + frac2) ** 0.5)
	end

	def p_value
		index = 0
		z = zscore
		z = z.abs
		found_p = nil
		while index < HANDY_Z_SCORE_CHEATSHEET.size do
		  if (z > HANDY_Z_SCORE_CHEATSHEET[index][1])
			found_p = HANDY_Z_SCORE_CHEATSHEET[index][0]
		  end
		  index += 1
		end
		found_p
	end

	def is_statistically_significant?(p = 0.05)
		p_value <= p
	end

	def describe_result_in_words
		begin
		  z = zscore
		rescue
		  return "Could not execute the significance test because one or more of the alternatives has not been seen yet."
		end
		p = p_value

		words = ""
		if (alternatives[0].participants < 10) || (alternatives[1].participants < 10)
		  words += "Take these results with a grain of salt since your samples are so small: "
		end

		alts = alternatives - [best_alternative]
		worst_alternative = alts.first

		words += "The best alternative you have is: [#{best_alternative.content}], which had "
		words += "#{best_alternative.conversions} conversions from #{best_alternative.participants} participants "
		words += "(#{best_alternative.pretty_conversion_rate}).  The other alternative was [#{worst_alternative.content}], "
		words += "which had #{worst_alternative.conversions} conversions from #{worst_alternative.participants} participants "
		words += "(#{worst_alternative.pretty_conversion_rate}).  "

		if (p.nil?)
		  words += "However, this difference is not statistically significant."
		else
		  words += "This difference is #{PERCENTAGES[p]} likely to be statistically significant, which means you can be "
		  words += "#{DESCRIPTION_IN_WORDS[p]} that it is the result of your alternatives actually mattering, rather than "
		  words += "being due to random chance.  However, this statistical test can't measure how likely the currently "
		  words += "observed magnitude of the difference is to be accurate or not.  It only says \"better\", not \"better "
		  words += "by so much\"."
		end
		words
	end

	# Controller Helpers

  def ab_test(test_name, alternatives = nil, options = {})
    if (Abingo.options[:enable_specification] && !@input.test_name.nil?)					# Camping-specific
      choice = @input.test_name																					# Camping-specific
    elsif (Abingo.options[:enable_override_in_session] && !@state.test_name.nil?)	# Camping-specific
      choice = @state.test_name																					# Camping-specific
    elsif (alternatives.nil?)
      choice = Abingo.flip(test_name)
    else
      choice = Abingo.test(test_name, alternatives, options)
    end

    if block_given?
      yield(choice)
    else
      choice
    end
  end

  def bingo!(test_name, options = {})
    Abingo.bingo!(test_name, options)
  end

	# Filter Helpers
	def set_abingo_identity # Camping-specific
		if @user
			Abingo.identity = @user.id
		else
			if @state.abingo_identity
				Abingo.identity = @state.abingo_identity
			else
				@state.abingo_identity = Abingo.identity = rand(10 ** 10).to_i
			end			
		end
	end
			
	def authenticate_abingo_administrator	
		return true if !@state.nil? && !@state.user_id.nil? && @state.user_id == abingo_administrator_user_id
		redirect('/abingo/restricted_access')
		return false
	end
	
	def abingo_administrator_user_id
		Abingo.options[:abingo_administrator_user_id] || 1
	end
	
end #ABingoCampingPlugin::Helpers

# Filters module for OAuth Camping Plugin.
# The module will be plugged in to the main app Helpers module. 
# Example:
#	module CampingOAuthProvider
#		include Camping::Session
#		include CampingFilters
#		extend  OAuthCampingPlugin
#		include OAuthCampingPlugin::Filters
#		
#		# ...
#	end
#
module ABingoCampingPlugin::Filters
	# Adds a before filters for the common controllers:
	#  - ABingoDashboard
	# Also adds a before filter on all controllers to ensure the user is set
	def self.included(mod)
		mod.module_eval do
			before :all do
				set_abingo_identity
			end
			
			before :ABingoDashboard do
				authenticate_abingo_administrator
			end					
		end
	end
end # ABingoCampingPlugin::Filters


# ABingo module for ABingo Camping Plugin.
# The module will be plugged into all controllers either: 
#   - directly such as in the standard common ABingo controllers (e.g. ABingoProvideRequestToken)
#   - or indirectly via the include_abingo_controllers of the ABingoCampingPlugin::Controllers module
# The module provides accessors, helper, authentication, signing, and authorization methods specific to ABingo 
#
module ABingoCampingPlugin::ABingo

	#protected


end

# Models module for the ABingo Camping Plugin.
# The module will be plugged in to the main app models module. 
# Example:
#	module CampingABingoTest::Models
#		include ABingoCampingPlugin::Models
#
#		class User < Base;
#			has_many :client_applications
#			has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]
#		
#		end
#		# ...
#	end
#
# This module requires the abingo-plugin gem to be installed as it will load the following models
#   - Experiment
#   - Alternative
#
module ABingoCampingPlugin::Models

	# --- Experiment ---------------------
	class Experiment < Camping::Models::Base
	  include ABingoCampingPlugin::Helpers

	  has_many :alternatives, :dependent => :destroy, :class_name => "Alternative"
	  validates_uniqueness_of :test_name

	  def cache_keys
	  [" Abingo::Experiment::exists(#{test_name})".gsub(" ", "_"),
		"Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_"),
		"Abingo::Experiment::short_circuit(#{test_name})".gsub(" ", "_")
	  ]
	  end
	  
	  def before_destroy
		cache_keys.each do |key|
		  Abingo.cache.delete key
		end
		true
	  end

	  def participants
		alternatives.sum("participants")
	  end

	  def conversions
		alternatives.sum("conversions")
	  end

	  def best_alternative
		alternatives.max do |a,b|
		  a.conversion_rate <=> b.conversion_rate
		end
	  end

	  def self.exists?(test_name)
		cache_key = "Abingo::Experiment::exists(#{test_name})".gsub(" ", "_")
		ret = Abingo.cache.fetch(cache_key) do
		  count = ABingoCampingPlugin::Models::Experiment.count(:conditions => {:test_name => test_name})
		  count > 0 ? count : nil
		end
		(!ret.nil?)
	  end

	  def self.alternatives_for_test(test_name)
		cache_key = "Abingo::#{test_name}::alternatives".gsub(" ","_")
		Abingo.cache.fetch(cache_key) do
		  experiment = ABingoCampingPlugin::Models::Experiment.find_by_test_name(test_name)
		  alternatives_array = Abingo.cache.fetch(cache_key) do
			tmp_array = experiment.alternatives.map do |alt|
			  [alt.content, alt.weight]
			end
			tmp_hash = tmp_array.inject({}) {|hash, couplet| hash[couplet[0]] = couplet[1]; hash}
			Abingo.parse_alternatives(tmp_hash)
		  end
		  alternatives_array
		end
	  end

	  def self.start_experiment!(test_name, alternatives_array, conversion_name = nil)
		ABingoCampingPlugin.logger.debug "Experiment> start_experiment(test_name=#{test_name}, alternatives_array=#{alternatives_array.inspect}, conversion_name=#{conversion_name})"

		conversion_name ||= test_name
		conversion_name.gsub!(" ", "_")
		cloned_alternatives_array = alternatives_array.clone
		ActiveRecord::Base.transaction do
		  experiment = ABingoCampingPlugin::Models::Experiment.find_or_create_by_test_name(test_name)
		  experiment.alternatives.destroy_all  #Blows away alternatives for pre-existing experiments.
		  while (cloned_alternatives_array.size > 0)
			alt = cloned_alternatives_array[0]
			
			if alt.is_a?(TrueClass) || alt.is_a?(FalseClass) 
				alt_to_store = alt.to_s
			else
				alt_to_store = alt
			end
			
			weight = cloned_alternatives_array.size - (cloned_alternatives_array - [alt]).size
			experiment.alternatives.build(:content => alt_to_store, :weight => weight,
			  :lookup => ABingoCampingPlugin::Models::Alternative.calculate_lookup(test_name, alt_to_store))
			cloned_alternatives_array -= [alt]
		  end
		  experiment.status = "Live"
		  experiment.save(false)  #Calling the validation here causes problems b/c of transaction.
		  Abingo.cache.write("Abingo::Experiment::exists(#{test_name})".gsub(" ", "_"), 1)

		  #This might have issues in very, very high concurrency environments...

		  tests_listening_to_conversion = Abingo.cache.read("Abingo::tests_listening_to_conversion#{conversion_name}") || []
		  tests_listening_to_conversion << test_name unless tests_listening_to_conversion.include? test_name
		  Abingo.cache.write("Abingo::tests_listening_to_conversion#{conversion_name}", tests_listening_to_conversion)
		  experiment
		end
	  end

	  def end_experiment!(final_alternative, conversion_name = nil)
		ABingoCampingPlugin.logger.debug "Experiment> end_experiment(final_alternative=#{final_alternative}, conversion_name=#{conversion_name})"
		
		conversion_name ||= test_name
		ActiveRecord::Base.transaction do
		  alternatives.each do |alternative|
			alternative.lookup = "Experiment completed.  #{alternative.id}"
			alternative.save!
		  end
		  update_attribute(:status, "Finished")
		  Abingo.cache.write("Abingo::Experiment::short_circuit(#{test_name})".gsub(" ", "_"), final_alternative)
		end
	  end

	end	

	# --- Alternative ---------------------
	class Alternative < Camping::Models::Base
	  include ABingoCampingPlugin::Helpers

	  belongs_to :experiment, :class_name => "Experiment"
	  serialize :content

	  def self.calculate_lookup(test_name, alternative_name)
		digest = Digest::MD5.hexdigest(Abingo.salt + test_name + alternative_name.to_s)
		ABingoCampingPlugin.logger.debug "calculate_lookup #{test_name} , #{alternative_name} > #{digest}"
		digest
	  end

	  def self.score_conversion(test_name)
		viewed_alternative = Abingo.find_alternative_for_user(test_name,
		  ABingoCampingPlugin::Models::Experiment.alternatives_for_test(test_name))
		ABingoCampingPlugin.logger.debug "Alternative> score_conversion #{test_name} > #{viewed_alternative}"
		self.update_all("conversions = conversions + 1", :lookup => self.calculate_lookup(test_name, viewed_alternative))
	  end

	  def self.score_participation(test_name)
		viewed_alternative = Abingo.find_alternative_for_user(test_name,
		  ABingoCampingPlugin::Models::Experiment.alternatives_for_test(test_name))
		ABingoCampingPlugin.logger.debug "Alternative>score_participation #{test_name} > #{viewed_alternative}"
		self.update_all("participants = participants + 1", :lookup => self.calculate_lookup(test_name, viewed_alternative))
	  end

	end #Abingo::Alternative
	
	# --- Migrations --------------------
	
	# Loads the 5 standard ABingo models defined in the abingo-plugin gem
	def self.included(mod)
		# @techarch : Reset the table names back to pre-Camping
		mod.module_eval do
			mod::Experiment.class_eval		{ set_table_name	"abingo_experiments" }
			mod::Alternative.class_eval 		{ set_table_name	"abingo_alternatives" }
		end
	end
	
	# Up-migrates the schema definition for the 5 ABingo models
	def self.up
		ActiveRecord::Schema.define do
			create_table "abingo_experiments", :force => true do |t|
			  t.string "test_name"
			  t.string "status"
			  t.timestamps
			end

			add_index "abingo_experiments", "test_name"
			#add_index "experiments", "created_on"

			create_table "abingo_alternatives", :force => true do |t|
			  t.integer :experiment_id
			  t.string :content
			  t.string :lookup, :limit => 32
			  t.integer :weight, :default => 1
			  t.integer :participants, :default => 0
			  t.integer :conversions, :default => 0
			end

			add_index "abingo_alternatives", "experiment_id"
			add_index "abingo_alternatives", "lookup"  #Critical for speed, since we'll primarily be updating by that.
		end
	end

	# Down-migrates the schema definition for the 2 ABingo models
	def self.down
		ActiveRecord::Schema.define do
			drop_table :abingo_experiments
			drop_table :abingo_alternatives
		end
	end

end

# Controllers module for the ABingo Camping Plugin.
# The module will be plugged in to the main app controllers module using:
#	 - extend to add class methods to the app controllers module
#	-  include_abingo_controllers to dynamically plugin the ABingo and Helpers modules inside each controller class
#		(this is why the call must be the last statement in the controllers module)
#
# Example:
#  module CampingABingoTest::Controllers
#		extend ABingoCampingPlugin::Controllers
#
#		# ...
#
#		include_abingo_controllers
#  end
#
module ABingoCampingPlugin::Controllers

	# Returns the source code for all common ABingo controllers
	def self.common_abingo_controllers
		<<-CLASS_DEFS
			class  ABingoMarkHuman < R '/abingo/mark_human'
				include ABingoCampingPlugin::ABingo
				include ABingoCampingPlugin::Helpers
				
				def post
					textual_result = "1"
					begin
						a = @input.a.to_i
						b = @input.b.to_i
						c = @input.c.to_i
						if (@env['REQUEST_METHOD'] == 'POST' && (a + b == c))
							Abingo.human!
						else
							textual_result = "0"
						end
					rescue #If a bot doesn't pass a, b, or c, to_i will fail.  This scarfs up the exception, to save it from polluting our logs.
						textual_result = "0"
					end
					
					return textual_result
				end
			end
			
			class ABingoDashboard < R '/abingo/dashboard'
				include ABingoCampingPlugin::ABingo
				include ABingoCampingPlugin::Helpers
				
				def get
					@experiments = ABingoCampingPlugin::Models::Experiment.all
					render :abingo_dashboard
				end
			end			
			
			class ABingoTerminateExperiment < R '/abingo/terminate'
				include ABingoCampingPlugin::ABingo
				include ABingoCampingPlugin::Helpers
				
				def post
					return(:abingo_dashboard) unless @input.alternative_id
					
					@alternative 	= ABingoCampingPlugin::Models::Alternative.find(@input.alternative_id)
					@experiment	= ABingoCampingPlugin::Models::Experiment.find(@alternative.experiment_id)
					experiment_name = @experiment.test_name
					
					if (@experiment.status != "Completed")
						@experiment.end_experiment!(@alternative.content)
						@abingo_notice = "Experiment '" + experiment_name + "' has been marked as ended.  All users will now see the chosen alternative."
					else
						@abingo_notice = "Experiment '" + experiment_name + "' is already ended."
					end
					
					render :abingo_termination_notice
				end
			end
			
			class ABingoRestrictedAccess < R '/abingo/restricted_access'
				def get
					render :abingo_dashboard_restricted_access
				end
			end

		CLASS_DEFS
	end
	
	# Includes the ABingo and Helpers modules inside each controller class using class_eval
	# (this is why the call must be the last statement in the controllers module)
	def include_abingo_controllers
		module_eval ABingoCampingPlugin::Controllers.common_abingo_controllers

		# Add ABing to each controller
		r.each do |x| 
			x.class_eval do
				include ABingoCampingPlugin::ABingo
				include ABingoCampingPlugin::Helpers
			end
		end			
	end
end

# Views module for the ABingo Camping Plugin.
# The module will be plugged in to the main app views module using:
#	 - extend to add class methods to the app views module
#	-  include_abingo_views to dynamically plugin the common ABingo views (e.g. authorize_view) 
#
# Example:
#  module CampingABingoTest::Views
#		extend ABingoCampingPlugin::Views
#
#		# ...
#
#		include_abingo_views
#  end
#
module ABingoCampingPlugin::Views
	def self.abingo_view_helpers
		<<-VIEW_HELPERS
				
			 def ab_test(test_name, alternatives = nil, options = {}, &block)

				if (Abingo.options[:enable_specification] && !params[test_name].nil?)
				  choice = params[test_name]
				elsif (Abingo.options[:enable_override_in_session] && !session[test_name].nil?)
				  choice = session[test_name]
				elsif (alternatives.nil?)
				  choice = Abingo.flip(test_name)
				else
				  choice = Abingo.test(test_name, alternatives, options)
				end

				if block
				  content_tag = capture(choice, &block)
				  block_called_from_erb?(block) ? concat(content_tag) : content_tag
				else
				  choice
				end
			  end

			  def bingo!(test_name, options = {})
				Abingo.bingo!(test_name, options)
			  end

			  #This causes an AJAX post against the URL.  That URL should call Abingo.human!
			  #This guarantees that anyone calling Abingo.human! is capable of at least minimal Javascript execution, and thus is (probably) not a robot.
			  def include_humanizing_javascript(url = "/abingo/mark_human", style = :jquery)  # Camping-specific
				ajax_call_script = nil
				if (style == :prototype)
				  ajax_call_script = "var a=Math.floor(Math.random()*11); var b=Math.floor(Math.random()*11);var x=new Ajax.Request('" + url + "', {parameters:{a: a, b: b, c: a+b}})"
				elsif (style == :jquery)
				  ajax_call_script = "var a=Math.floor(Math.random()*11); var b=Math.floor(Math.random()*11);var x=jQuery.post('" + url + "', {a: a, b: b, c: a+b})"
				end
				#ajax_call_script.nil? ? "" : "<script type='text/javascript'>" + ajax_call_script + "</script>"
				
				return unless !ajax_call_script.nil?
				
				script :type=> 'text/javascript' do
					%Q|ajax_call_script|
				end				
				
			  end
					
		VIEW_HELPERS
	end

	# Returns the source code for all common ABingo views such as error views (e.g. authorize_failure)
	def self.common_abingo_views
		<<-VIEW_DEFS
		
			def abingo_dashboard
				div.abingo_dashboard! do
					h1 "ABingo All Experiments"
					
					@experiments.each do | experiment |
						abingo_experiment(experiment)
					end				
				end
			end	
			
			def abingo_experiment(experiment)
				short_circuit = "" 
				Abingo.cache.read("ABingoCampingPlugin::Models::Experiment::short_circuit("+experiment.test_name+")".gsub(" ", "")) 
			
				h2 { span { experiment.id.to_s + ' - ' + experiment.test_name.titleize }
						span("[Completed]") if experiment.status != "Live"
					}
					
				table.abingo_experiment_table :style=>"" do
					tr { 	th {"Name"}; 
							th {"Participants"}; 
							th {"Conversions"};
							th {"Notes" }
						}
						
					tr.abingo_experiment_row { 	td {"Experiment Total: "};
							td { experiment.participants.to_s };
							td { experiment.conversions.to_s + '(' + experiment.pretty_conversion_rate + ')' };
							td { };
						}
						
					experiment.alternatives.each do | alternative |  
						tr.abingo_alternative_row { 	td { h(alternative.content) };
								td { alternative.participants.to_s };
								td { alternative.conversions.to_s + '(' + alternative.pretty_conversion_rate + ')' };
								td { 
										unless experiment.status != "Live"
										
											onclickfn = <<-JAVASCRIPT
												if (confirm('Are you sure you want to terminate this experiment?  This is not reversible.')) { 
													var f = document.createElement('form'); 
													f.style.display = 'none'; 
													this.parentNode.appendChild(f); 
													f.method = 'POST'; 
													f.action = this.href;
													f.submit();
												};
												return false;
											JAVASCRIPT
											
											a "Terminate this Alternative", :onclick=>onclickfn, :href=> "/abingo/terminate?alternative_id=" + alternative.id.to_s
										else
											if alternative.content == short_circuit
												span "(All users seeing this.)"
											end
										end
									};
							}					
					end
					
					tr.abingo_experiment_row { 	td :colspan=>'24' do 
								span("Significance test results: " + experiment.describe_result_in_words)
							end
						}
					
				end
			end
	
			def abingo_termination_notice
				h1 "ABingo Dashboard - Termination Notice"
				div { @abingo_notice }
			end

			def abingo_dashboard_restricted_access
				h1 "ABingo Dashboard - Restricted Access"
				div "Only the administrator can access the ABingo Dashboard."
			end
			
		VIEW_DEFS
	end
	
	# Includes all common ABingo views inside the views module using module_eval
	# (this is why the call must be the last statement in the views module)
	def include_abingo_views
		module_eval ABingoCampingPlugin::Views.abingo_view_helpers
		module_eval ABingoCampingPlugin::Views.common_abingo_views

		module_eval do
			app_module_name = self.to_s.split("::").first	
			mab_class_name = "#{app_module_name}::Mab"	
			mab_class = mab_class_name.constantize

#			unless mab_class.public_instance_methods.include? 'register' 
#				module_eval ABingoCampingPlugin::Views.register_view
#			end
		end
		
	end
end
