require "sinatra/base"

require "omniauth"
require "omniauth-google-oauth2"
require "omniauth-github"
require "./lib/omniauth-slack"

require "dotenv/load"

SESSION_SECRET = ENV.fetch('SESSION_SECRET')

EMAIL_DOMAIN = ENV["EMAIL_DOMAIN"]

GOOGLE_CLIENT_OPTIONS = [ENV.fetch("GOOGLE_CLIENT_ID"), ENV.fetch("GOOGLE_CLIENT_SECRET"), {}]
GOOGLE_CLIENT_OPTIONS.last[:hd] = EMAIL_DOMAIN if EMAIL_DOMAIN

GITHUB_CLIENT_OPTIONS = [ENV.fetch("GITHUB_CLIENT_ID"), ENV.fetch("GITHUB_CLIENT_SECRET"), { scope: "user,user:email"}]

SLACK_CLIENT_OPTIONS = [ENV.fetch("SLACK_CLIENT_ID"), ENV.fetch("SLACK_CLIENT_SECRET")]

class App < Sinatra::Base
  use Rack::Protection::AuthenticityToken

  use OmniAuth::Builder do
    provider OmniAuth::Strategies::GoogleOauth2, *GOOGLE_CLIENT_OPTIONS
    provider OmniAuth::Strategies::GitHub, *GITHUB_CLIENT_OPTIONS
    provider OmniAuth::Strategies::Slack, *SLACK_CLIENT_OPTIONS
  end

  set :sessions, true
  set :session_secret, SESSION_SECRET

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
    session[:user] = {
      google: {
        uid: request.env["omniauth.auth"]["uid"],
        info: request.env["omniauth.auth"]["info"],
      }
    }
    redirect "/"
  end

  get "/auth/github/callback" do
    current_user[:github] = {
      uid: request.env["omniauth.auth"]["uid"],
      info: request.env["omniauth.auth"]["info"],
    }
    redirect "/"
  end

  get "/auth/slack/callback" do
    current_user[:slack] = {
      uid: request.env["omniauth.auth"]["uid"],
      info: request.env["omniauth.auth"]["info"],
    }
    redirect "/"
  end
end
