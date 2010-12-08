#	NOTE: This sample is a basic skeletonfor the CampingABingoTest web app
#  which does NOT yet contain any integration with ABingo.
#
#	You can use this as a starting point to follow along the instructions to add
# 	ABingo support based on the blog post series: http://blog.monnet-usa.com/?p=322
#
gem 'camping' , '~> 2.0'	
gem 'filtering_camping' , '~> 1.0'	

%w(rubygems active_record active_support erb  fileutils json markaby md5   
camping camping/session filtering_camping 
).each { |lib| require lib }

Camping.goes :CampingABingoTest

module CampingABingoTest
	include Camping::Session
	include CampingFilters

	is_under_camping_server = (Camping.const_defined? :Server) 	
	if is_under_camping_server 
		app_logger = Logger.new(File.dirname(__FILE__) + '/camping-abingo-test.log')
		app_logger.level = Logger::DEBUG
	else
		app_logger = Logger.new($STDERR)
		app_logger.level = Logger::ERROR
	end
	Camping::Models::Base.logger = app_logger
	
	def CampingABingoTest.create
		dbconfig = YAML.load(File.read('config/database.yml'))								
		environment = ENV['DATABASE_URL'] ? 'production' : 'development'
		Camping::Models::Base.establish_connection  dbconfig[environment]
		
		CampingABingoTest::Models.create_schema :assume => (CampingABingoTest::Models::User.table_exists? ? 1.1 : 0.0)
	end
end

module CampingABingoTest::Models
	class User < Base;
	end

	class CreateUserSchema < V 1.0
		def self.up
			create_table :campingabingotest_users, :force => true do |t|
				t.integer 	:id, :null => false
				t.string		:username
				t.string		:password
			end
			
			User.create :username => 'admin', :password => 'camping'
		end
		
		def self.down		
			drop_table :campingabingotest_users
		end
	end

end

module CampingABingoTest::Helpers
end

module CampingABingoTest::Controllers
	class Index
		def get 
			render :index
		end
	end

	class Landing < R '/landing'
		def get
			render :landing
		end
	end
	
	class SignIn < R '/signin'			
		def get
			render :signin
		end
		
		def post
			@user = User.find_by_username_and_password(input.username, input.password)

			if @user
				@state.user_id = @user.id

				if @state.return_to.nil?
					redirect R(Welcome)
				else
					return_to = @state.return_to
					@state.return_to = nil
					redirect(return_to)
				end
			else
				@info = 'Wrong username or password.'
			end
			
			render :signin		
		end
	end	
	
	class SignOut < R '/signout'		
		def get
			@state.user_id = nil
			
			render :index
		end
	end
	
	class SignUp < R '/signup'
		def get
			render :signup
		end
		
		def post
			@user = User.find_by_username(input.username)
			if @user
				@info = 'A user account already exist for this username.'
			else
				@user = User.new :username => input.username,
					:password => input.password
				@user.save
				if @user
					@state.user_id = @user.id
					redirect R(Welcome)
				else
					@info = @user.errors.full_messages unless @user.errors.empty?
				end
			end
			render :signup
		end
	end
	
	class Welcome < R '/welcome'
		def get
			render :welcome
		end
	end
	
end #Controllers

module CampingABingoTest::Views
	def layout
		html do
		
			head do
				title "Ruby Camping ABingo Plugin Demo"
				
				style  :type => 'text/css' do
<<-STYLE	

/* --- General Test App Styles --- */			

body {
	padding:0 0 0 0;
	margin:5px;
	font-family:'Lucida Grande','Lucida Sans Unicode',sans-serif;
	font-size: 0.8em;
	color:#303030;
	background-color: #fbf9b5;
}

a {
	color:#303030;
	text-decoration:none;
	border-bottom:1px dotted #505050;
}

a:hover {
	color:#303030;
	background: yellow;
	text-decoration:none;
	border-bottom:4px solid orange;
}

h1 {
	font-size: 14px;
	color: #cc3300;
}

table {
	font-size:0.9em;
	width: 1050px;
	}

tr 
{
	background:lightgoldenRodYellow;
	vertical-align:top;
}

th
{
	font-size: 0.9em;
	font-weight:bold;
	background:lightBlue none repeat scroll 0 0;
	
	text-align:left;	
}

#header
{
	width: 100%;
	height: 30px;
	border-bottom: 4px solid #ccc;
}

#header_title
{
	float: left;
}

#top_nav
{
	float: right;
}

#footer
{
	width: 100%;
	border-top: 4px solid #ccc;
}


#footer_notices
{
	width: 100%;
	border-top: 4px solid #ccc;
}

#home
{
	background-color: #C9E3F5;
	padding: 10px;
	height: 300px;
}

#debug_panel
{
	background-color: wheat;
	padding: 10px;
}

.xyz
{
	background-color: #D1F2A5;
	padding: 10px;
	height: 300px;
}

.xyz h1 
{
	color: #9D9F89;
}

#special_promo
{
	margin: 20px;
}

#landing a:hover
{
	background-color: #B2DE93;
	border-bottom-color:green;
}

#marketing
{
	width: 480px;
	height: 100px;
	margin: 20px;
}

#benefits
{
	float: left;
	width: 300px;
	height: 100px;
	font-size: 1.3em;
	font-weight: bold;
	color: green;
	background-color: #B2DE93;
}

#actnow
{
	float: right;
	width: 180px;
	height: 100px;
	text-align: center;
	background-color: #8BC59B;
}

#signup_btn
{
	background-color:#91F1A0;
	border:4px solid green;
	font-size:1.5em;
	font-weight:bold;
	height:72px;
	margin: 10px 20px 10px 22px;
	width:130px;
}

#actnow a:hover #signup_btn
{
	background-color: #69F17F;
	color: #007300;
	border: 4px solid #00AA00;
}

/* --- ABingo Dashboard Styles ---*/

#abingo_dashboard
{
	background-color: white;
	padding: 10px;
}

abingo_experiment_table
{
	width: 100%;
}

.abingo_experiment_row
{
}

.abingo_alternative_row
{
	color: red;
	font-weight: bold;
}

.abingo_debug
{
	display: block;
	width: 100%;
}

.abingo_explain
{
	color: #CCC;
	font-style:italics;
}

	
STYLE
				end
			end #head
		
		  body do
			div.header! do
				div.header_title! "Ruby Camping ABingo Plugin Demo"
				div.top_nav! do
					a "Home", :href=>"/"
					span " | "
					if @state.nil? || @state.user_id.nil?
						a "Sign-In", 	:href=>'/signin'
						span " | "
						a "Sign-Up", 	:href=>'/signup'
					else
						a "XYZ", :href=>"/welcome"
						span " | "
						a "Sign-Out",	:href=>'/signout'
					end
				end
			end
			
			self << yield

			div.footer! do
				div.debug_panel! do
					h4 "Debugging Information:"
					h5 "State:"
					div "#{@state.inspect}"
				end
				
				div.footer_notices! { "Copyright &copy; 2010 &nbsp; -  #{ a('Patrick McKenzie', :href => 'http://www.bingocardcreator.com/abingo') } and #{ a('Philippe Monnet', :href => 'http://blog.monnet-usa.com/') }  " }
			end
		  end

		end
	end

	
	def index
		div.home! do
			h1 'My CampingABingoTest App'
			
			a "XYZ SAAS Application Landing page variations", :href=>"/landing"; br;
		end
	end
	
	def landing
		div.xyz do
			h1 'XYZ SAAS Application'
			
			div.marketing! do
				div.benefits! do
					ul do
						li "Save XYZ time in half"
						li "Reduce XYZ cost by 25%"					
						li "Improve quality"
					end
				end
				
				div.actnow! do
					signup_text = "Sign-Up Now!"
					
					a :href=>"/signup" do
						div.signup_btn!  signup_text
					end
				end
			end
		end
	end
	
	def signin
		div.xyz do
			h1 'XYZ SAAS Application Sign-In'
			div @info if @info
			
			form :action => R(SignIn), :method => 'post' do
				label 'Username', :for => 'username'; br
				input :name => 'username', :type => 'text'; br

				label 'Password', :for => 'password'; br
				input :name => 'password', :type => 'text'; br

				input :type => 'submit', :name => 'signin', :value => 'Sign-In'
			end
		end
	end
	
	def signup
		div.xyz do
			h1 'XYZ SAAS Application Sign-Up'
			div @info if @info
			
			form :action => R(SignUp), :method => 'post' do
				label 'Username', :for => 'username'; br
				input :name => 'username', :type => 'text'; br

				label 'Password', :for => 'password'; br
				input :name => 'password', :type => 'password'; br;br

				input :type => 'submit', :name => 'signup', :value => 'Sign-Up'
			end
		end
	end
	
	def welcome
		div.xyz do	
			h1 'Welcome'
		end
	end
	
end

CampingABingoTest.create
 