require "sinatra/base"

require "omniauth"
require "omniauth-google-oauth2"

require "dotenv/load"

SESSION_SECRET = ENV.fetch('SESSION_SECRET')

GOOGLE_CLIENT_OPTIONS = [ENV.fetch("GOOGLE_CLIENT_ID"), ENV.fetch("GOOGLE_CLIENT_SECRET"), {}]
GOOGLE_CLIENT_OPTIONS.last[:hd] = ENV["GOOGLE_CLIENT_HD"] if ENV["GOOGLE_CLIENT_HD"]

class App < Sinatra::Base
  use Rack::Protection::AuthenticityToken

  use OmniAuth::Builder do
    provider OmniAuth::Strategies::GoogleOauth2, *GOOGLE_CLIENT_OPTIONS
  end

  set :sessions, true
  set :session_secret, SESSION_SECRET

  User = Struct.new(:google, keyword_init: true)
  UserGoogleAttributes = Struct.new(:uid, :info, keyword_init: true)

  helpers do
    def h(text)
      Rack::Utils.escape_html(text)
    end

    def current_user
      session[:user]
    end
  end

  before do
    next if request.path.start_with?("/auth/")
    next if request.path == "/login"
    next if current_user
    redirect "/login"
  end

  get "/" do
    erb :index
  end

  get "/login" do
    erb :login
  end

  get "/auth/google_oauth2/callback" do
    session[:user] = User.new(
      google: UserGoogleAttributes.new(
        uid: request.env["omniauth.auth"]["uid"],
        info: request.env["omniauth.auth"]["info"],
      )
    )
    redirect "/"
  end
end
