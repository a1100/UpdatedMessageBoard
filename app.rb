require 'bundler'
Bundler.require

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/main.db')
require './models.rb'

use Rack::Session::Cookie, :key => 'rack.session',
    :expire_after => 2592000,
    :secret => SecureRandom.hex(64)

get '/' do
  erb :login
end

get '/login' do
  @message = session[:message]
  session[:message] = ""

  @users = User.all

  erb :login
end

post '/check_user' do
  u = User.first(:username => params[:username])

  if u

    if BCrypt::Password.new(u.password) == params[:password]
      session[:uid] = u.id
      session[:hello] = "Welcome, #{u.first}!"
      redirect '/threads'
    else
      session[:message] = "Username or password incorrect. Not a registered user? Click the sign up link below."
      redirect '/login'
    end
  elsif params[:username] == ""
    session[:message] = "Please enter a username."
    redirect '/login'
  else
    session[:message] = "The username, #{params[:username]}, has not yet been registered."
    redirect '/login'
  end
end


get '/signup' do
  @message = session[:message]
  session[:message] = ""

  erb :signup
end

post '/create_user' do
  u = User.first(:username => params[:username])
  if u
    session[:message] = "The username, #{params[:username]}, is already taken. Please try again."
    redirect '/signup'
  else
    if params[:password] != params[:confirm]
      session[:message] = "Passwords do not match."
      redirect '/signup'
    else
      @hello = session[:hello]
      session[:hello] = "Welcome, #{params[:username]}!"

      u = User.new
      u.username = params[:username]
      u.first = params[:first]
      u.password = BCrypt::Password.create(params[:password])
      u.save
      session[:message] = "Welcome to __! Now login with the username and password you just created."
      redirect '/login'
    end
  end
end


get '/threads' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end

  @threads = Topic.all
  erb :threads
end

get '/thread/:thread_id/posts' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  @thread = Topic.first(:id => params[:thread_id])
  @posts = @thread.posts
  erb :posts
end


get '/leave' do
  session.clear
  redirect '/'
end

post '/create_thread' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  t = Topic.new
  t.name = params[:name]
  t.user = User.first(:id => session[:uid])
  t.date = Time.now
  t.save
  redirect '/threads'
end

post '/thread/:thread_id/create_post' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  t = Topic.first(:id => params[:thread_id])
  p = Post.new
  p.title = params[:title]
  p.content = params[:content]
  p.user_id = session[:uid]
  p.time = Time.now
  p.topic = t
  p.save
  redirect "/thread/#{t.id}/posts"

end

get '/users/:thread.user.id' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  erb :users
end

# DELETE
get '/thread/:thread_id/delete' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  # first check that the user created the thread

  t = Topic.first(:id => params[:thread_id])
  if t.user_id == session[:uid]
    t.destroy
    redirect '/threads'
  else
    session[:message] = "You do not have permission to edit this thread."
    redirect '/threads'
  end
end

# UPDATE

get '/thread/:thread_id/edit' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end

  # first check that the user created the thread
  @t = Topic.where(:id => params[:thread_id]).first
  # check if logged in user created the thread. if they did continue else send a message saying they do not have permission to edit this thread.
  if @t.user.id == session[:uid]
    erb :edit
  else
    session[:message] = "You do not have permission to edit this thread."
  end
end

# UPDATE
post '/thread/:thread_id/update' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  t = Topic.where(:id => params[:thread_id]).first
  t.name = params[:name]
  t.save

  redirect '/threads'
end

get '/post/:id/delete' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end

  p = Post.where(:id => params[:id]).first
  @topic = p.topic_id
  if p.user_id == session[:uid]
    p.destroy
    redirect "/thread/#{@topic}/posts"
  else
    session[:message] = "You do not have permission to edit this post."
    redirect "/thread/#{@topic}/posts"
  end
end

get '/post/:id/edit' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  @p = Post.where(:id => params[:id]).first
  # check if logged in user created the thread. if they did continue else send a message saying they do not have permission to edit this thread.
    erb :edit_post
end

post '/post/:id/update' do
  if session[:uid] == nil
    session[:message] = "You must login first."
    redirect '/login'
  end
  p = Post.where(:id => params[:id]).first
  @thread_id2 = p.topic_id
  p.title = params[:name]
  p.content = params[:content]
  p.save
  redirect "/thread/#{@thread_id2}/posts"
end

get '/user/:uid' do
  erb :user
end

get '/userlist' do
  erb :userlist
end

