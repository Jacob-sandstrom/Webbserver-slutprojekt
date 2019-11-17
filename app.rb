Db = SQLite3::Database
Pwd = BCrypt::Password

class App < Sinatra::Base

	enable :sessions

	before do 
		p "#########"
		p session
		p "#########"

	end

	before '/admin*' do 
		# check if admin and redirect
	end

	def login(id)
        session[:user_id] = id
	end
	
	get '/' do
		session[:user_id]? (@username = Users.get_name_from_id(session[:user_id])) : (@username = "Not logged in")
		slim :index
	end

	
	get '/users/new/?' do
		slim :'users/new'
	end

	post '/users/new' do
		username = params["username"]
		password = params["password"]
		success = Users.create_user(username, password)
		login(Users.get_id_from_name(username)) if success
		
		redirect "/users"
	end

	get "/users/?" do

		if session[:user_id]
			@username = Users.get_specific("name", "id", session[:user_id])
			@user_id = session[:user_id]
			slim :"users/show"
		else
			redirect "/users/login"
		end

	end

	get '/users/login' do
		slim :"users/login"
	end

	post "/users/login" do 
		username = params["username"]
		password = params["password"]
		success = Users.auth_user(username, password)
		login(Users.get_id_from_name(username)) if success

		redirect "/users/"
	end

	
end