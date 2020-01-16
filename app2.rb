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
		
		@user = User.fetch({id: session[:user_id]})
		

		if @user != []
			@username = @user[0].name
			@is_admin = @user[0].is_admin
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
		@post = Post.fetch({}, {tag: nil}, [["vote", "DESC"]])
		@tags = Tag.fetch({})
		slim :index
	end

	get '/top/?:tag?' do
		@tag = params["tag"]
		@tags = Tag.fetch({})
        if @tag
            @post = Post.fetch({:"tag.id" => @tag}, {tag: nil}, [["vote", "DESC"]])
        else
            @post = Post.fetch({}, {tag: nil}, [["vote", "DESC"]])
        end
		slim :index
	end
	
	get '/newest/?:tag?' do
		@tag = params["tag"]
        @tags = Tag.fetch({})
        if @tag
            @post = Post.fetch({:"tag.id" => @tag}, {tag: nil}, [["post.id", "DESC"]])
        else
            @post = Post.fetch({}, {tag: nil}, [["post.id", "DESC"]])
        end
		slim :index
	end

	post '/goto' do
		sort = params["sort"]
		tag = params["tag"]
		sort = "top" if !sort

		redirect "/#{sort}/#{tag}"
	end
	
	post '/post/delete/' do
		Post.remove({id: params["id"]})
		redirect '/'
	end
 
	post '/comment/delete/' do
		Comment.remove({id: params["id"]})
		redirect '/'
	end

	post '/user/delete/' do
		User.remove({id: params["id"]})
		session.delete(:user_id) if params["id"].to_i == session[:user_id]
		redirect '/'
	end

	
	get '/user/new/?' do
		slim :'user/new'
	end

	post '/user/new' do
		username = params["username"]
		password = params["password"]
		user = User.create_user(username, password)
		login(user.id) if user
		
		redirect "/user"
	end

	get "/user/?" do

        if session[:user_id]
            @user = User.fetch({id: session[:user_id]})[0]
			@username = @user.name
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
		user = User.auth_user(username, password)
		login(user.id) if user

		redirect "/user/"
	end

	get "/post/new" do
		@tags = Tag.fetch({})
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
        post = Post.create({title: title, content: content, creation_time: creation_time, user_id: user_id})
        Tagging.add(post.id, tags, user_id)
		redirect "/"
	end

	get "/post/show/:id" do 
		id = params["id"]

        @post = Post.fetch({"post.id" => id}, {tag: nil, comment: {user: nil}, user: nil})[0]
        p @post
   
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
        p content

		Comment.create({content: content, creation_time: Time.now.to_s, user_id: session[:user_id], post_id: post_id, comment_id: comment_id})
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
		@user = User.fetch({})
		slim :"admin/user"
	end



	
	
end