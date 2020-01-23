Db = SQLite3::Database
Pwd = BCrypt::Password

class App < Sinatra::Base

	enable :sessions

	before "/*" do |path|
		@path = path
		p path
		p "#########"
		p session
		p "#########"
		
		@user_data = User.get_where("name, is_admin", "id", session[:user_id])
		

		if @user_data != []
			@username = @user_data[0]["name"]
			@is_admin = @user_data[0]["is_admin"]
		end

		
		if !session[:user_id]
			if path.include?("comment/new") || path.include?("post/new")
				redirect "/user/login"
			end
		end
	end


	

	before '/admin*' do 
		# check if admin and redirect
		if @is_admin != 1
			redirect '/'
		end
	end



	def login(id)
        session[:user_id] = id
	end
	
	get '/' do
		@post = Post.get_with_tag("top", nil)
		@tags = Tag.get_all()
		slim :index
	end

	# get '/:sort?/?:tag?/?' do
	# 	@tag = params["tag"]
	# 	@tags = Tag.get_all()
	# 	if @tag
	# 		@post = Post.with_tag(@tag, [["post.vote", "DESC"]])
	# 	else
	# 		@post = Post.top
	# 	end
	# 	slim :index
	# end

	get '/top/?:tag?' do
		@tag = params["tag"]
		@tags = Tag.get_all()
		@post = Post.get_with_tag("top", @tag)
		slim :index
	end
	
	get '/newest/?:tag?' do
		@tag = params["tag"]
		@tags = Tag.get_all()
		@post = Post.get_with_tag("newest", @tag)
		slim :index
	end

	post '/goto' do
		sort = params["sort"]
		tag = params["tag"]
		sort = "top" if !sort

		redirect "/#{sort}/#{tag}"
	end
	
	post '/post/delete/' do
		Post.delete_at(params["id"])
		redirect '/'
	end
 
	post '/comment/delete/' do
		Comment.delete_at(params["id"])
		redirect '/'
	end

	post '/user/delete/' do
		User.delete_at(params["id"])
		session.delete(:user_id) if params["id"].to_i == session[:user_id]
		redirect '/'
	end

	
	get '/user/new/?' do
		slim :'user/new'
	end

	post '/user/new' do
		username = params["username"]
		password = params["password"]
		success = User.create_user(username, password)
		login(User.get_id_from_name(username)) if success
		
		redirect "/user"
	end

	get "/user/?" do

		if session[:user_id]
			@username = User.get_specific("name", "id", session[:user_id])
			@user_id = session[:user_id]
			slim :"user/show"
		else
			redirect "/user/login"
		end

	end

	get '/user/login' do
		slim :"user/login"
	end
	get '/user/logout' do
		session.delete(:user_id)
		redirect '/'
	end

	post "/user/login" do 
		username = params["username"]
		password = params["password"]
		success = User.auth_user(username, password)
		login(User.get_id_from_name(username)) if success

		redirect "/user/"
	end

	get "/post/new" do
		@tags = Tag.get_all()
		slim :"post/new"
	end

	post "/post/new" do
		title = params["Title"]
		content = params["content"]

		tags = params
		tags.delete("Title")
		tags.delete("content")
		
		tags = tags.map {|tag| tag[1]}

		creation_time = Time.now.to_s
		user_id = session[:user_id]
		Post.create(title, content, creation_time, user_id, tags)
		redirect "/"
	end

	get "/post/show/:id" do 
		id = params["id"]

		@post, @comment, @tags = Post.get_sorted_by_id(id)
   
		slim :"post/show"
	end 
	  
	get "/comment/new/:post_id/:comment_id" do
		@post_id = params["post_id"]
		@comment_id = params["comment_id"] 
		@comment_id = "" if @comment_id == nil
		slim :"comment/new"
	end
	
	post "/comment/new/:post_id/:comment_id" do
		post_id = params["post_id"]
		content = params["content"]
		comment_id = params["comment_id"]


		Comment.create(content, Time.now.to_s, session[:user_id], post_id, comment_id)
		redirect "/post/show/#{post_id}"

	end

	post "/vote/change/:id" do
		post_id = params["id"]
		value = params["vote"]
		path = params["path"]
		user_id = session[:user_id]

		Vote.change(post_id, user_id, value)
		Post.set_score(post_id, Vote.get_score(post_id))
		redirect "/#{path}"
	end

	get "/admin/user/?" do
		@user = User.get()
		slim :"admin/user"
	end



	
	
end