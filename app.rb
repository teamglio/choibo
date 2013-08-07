require 'sinatra'
require 'dotenv'
require 'firebase'
require 'nestful'
require 'kolb'
require_relative 'lib/choibo.rb'

configure do
	Dotenv.load if settings.development?
	Firebase.base_uri = "https://glio-mxit-users.firebaseio.com/#{ENV['MXIT_APP_NAME']}/"
end

before do
	@mixup_ad = Nestful.get("http://serve.mixup.hapnic.com/#{ENV['MXIT_APP_NAME']}").body
end

get '/' do
	create_user unless get_user
	track_login	
	erb :home
end

get '/book/:book_title/page/:page_number' do
	book = KOLB::Book.from_yaml(open("public/books/#{params[:book_title]}.yaml"))	
	@page = book.page(params[:page_number].to_i)
	@actions = book.actions_for_page(params[:page_number].to_i)
	erb :page
end

get '/interested' do
	mxit_user = MxitUser.new(request.env)
	Firebase.update(mxit_user.user_id, {:interested => true})
	erb :home
end

get '/disinterested' do
	mxit_user = MxitUser.new(request.env)
	Firebase.update(mxit_user.user_id, {:interested => false})
	erb :home
end

helpers do
	def get_user
		mxit_user = MxitUser.new(request.env)
		data = Firebase.get(mxit_user.user_id).response.body
		data == "null" ? nil : data
	end
	def create_user
		mxit_user = MxitUser.new(request.env)
		Firebase.set(mxit_user.user_id, {:date_joined => Time.now})
	end
	def track_login
		mxit_user = MxitUser.new(request.env)
		Firebase.update(mxit_user.user_id, {:last_login => Time.now})		
	end
end