Db = SQLite3::Database
Pwd = BCrypt::Password

class App < Sinatra::Base

	enable :sessions

	before "/*" do |path|
		p path
		p "#########"
		p session
		p "#########"
		
		@username = Users.get_name_from_id(session[:user_id])

		
		if !session[:user_id]
			if path.include?("comments/new") || path.include?("posts/new")
				redirect "/users/login"
			end
		end
	end


	

	before '/admin*' do 
		# check if admin and redirect
	end



	def login(id)
        session[:user_id] = id
	end
	
	get '/' do
		@posts = Posts.top
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
	get '/users/logout' do
		session.delete(:user_id)
		redirect '/'
	end

	post "/users/login" do 
		username = params["username"]
		password = params["password"]
		success = Users.auth_user(username, password)
		login(Users.get_id_from_name(username)) if success

		redirect "/users/"
	end

	get "/posts/new" do
		@tags = Tags.get_all()
		slim :"posts/new"
	end

	post "/posts/new" do
		title = params["Title"]
		content = params["content"]

		tags = params
		tags.delete("Title")
		tags.delete("content")
		
		tags = tags.map {|tag| tag[1]}

		creation_time = Time.now.to_s
		user_id = session[:user_id]
		Posts.create(title, content, creation_time, user_id, tags)
		redirect "/"
	end

	get "/posts/show/:id" do 
		id = params["id"]

		@post, @comments, @tags = Posts.get_sorted_by_id(id)
   
		slim :"posts/show"
	end 
	  
	get "/comments/new/:post_id/:comment_id" do
		@post_id = params["post_id"]
		@comment_id = params["comment_id"] 
		@comment_id = "" if @comment_id == nil
		slim :"comments/new"
	end
	
	post "/comments/new/:post_id/:comment_id" do
		post_id = params["post_id"]
		content = params["content"]
		comment_id = params["comment_id"]


		Comments.create(content, Time.now.to_s, session[:user_id], post_id, comment_id)
		redirect "/posts/show/#{post_id}"

	end
	
end