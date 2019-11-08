Db = SQLite3::Database
Pwd = BCrypt::Password

class App < Sinatra::Base

	enable :sessions

	before do 
		@db = SQLite3::Database.new('db/db.db')
		@db.results_as_hash = true
		p "#########"
		p session
		p "#########"

	end

	before '/admin*' do 
		# check if admin and redirect
	end

	def get_user_id(username)
		user_id = @db.execute("SELECT id FROM users WHERE username IS ?", username)[0]
		
		if user_id
			return user_id["id"]
		else
			return nil
		end
	end


	def create_user(username, password)
		user_id = get_user_id(username)
   
        if user_id != nil
            return false
        end
       
        hashed = Pwd.create(password)
		@db.execute("INSERT INTO users (username, pwd_hash) VALUES (?, ?);", username, hashed)
		session[:user_id] = get_user_id(username)	
        return true
    end
   
    def auth_user(username, password)
        user_id = get_user_id(username)
   
		if !user_id
            return false
        end
       
		db_hash = Pwd.new(@db.execute("SELECT pwd_hash FROM users WHERE username IS ?;", username)[0][0])
		
        success = db_hash == password
		
		if success
			session[:user_id] = user_id
			return true
		end

		return false
	end
	
	get '/users/new/?' do
		slim :'users/new'
	end

	post '/users/new' do
		username = params["username"]
		password = params["password"]
		if create_user(username, password)
			redirect "/users"
		end
	end

	get "/users/?" do

		if session[:user_id]
			@username = @db.execute("SELECT username FROM users WHERE id = ?", session[:user_id])[0]["username"]
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
		success = auth_user(username, password)

		redirect "/users/"
	end

	
end