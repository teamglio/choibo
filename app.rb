require 'rubygems'
require 'bundler'
Bundler.require(:default) 
require_relative 'lib/choibo.rb'

configure do
	Dotenv.load if settings.development?
	Firebase.base_uri = "https://glio-mxit-users.firebaseio.com/#{ENV['MXIT_APP_NAME']}/"
	AWS.config(
	  :access_key_id => ENV['AWS_KEY'],
	  :secret_access_key => ENV['AWS_SECRET']
	)	
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

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'Choibo feedback',
	  :from => 'mxitappfeedback@glio.co.za',
	  :to => 'mxitappfeedback@glio.co.za',
	  :body_text => params['feedback'] + ' - ' + MxitUser.new(request.env).user_id
	  )
	erb "Thanks! <a href='/'>Back</a>" 
end

get '/stats' do
	erb "Users: #{Firebase.get('').body.count} <br /> Interested: #{Firebase.get('').body.values.select {|v| v['interested'] == true}.count} <br /> Disinterested: #{Firebase.get('').body.values.select {|v| v['interested'] == false}.count} <br />Conversion: #{Firebase.get('').body.values.select {|v| v['interested'] == true}.count / Firebase.get('').body.count.to_f}"
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