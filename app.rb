require "sinatra/base"

require "omniauth"
require "omniauth-google-oauth2"
require "omniauth-github"
require "./lib/omniauth-slack"
require "omniauth-esa"

require "./lib/service"

require "dotenv/load"

SESSION_SECRET = ENV.fetch('SESSION_SECRET')

EMAIL_DOMAIN = ENV["EMAIL_DOMAIN"]

GOOGLE_CLIENT_OPTIONS = [ENV.fetch("GOOGLE_CLIENT_ID"), ENV.fetch("GOOGLE_CLIENT_SECRET"), {}]
GOOGLE_CLIENT_OPTIONS.last[:hd] = EMAIL_DOMAIN if EMAIL_DOMAIN

GITHUB_CLIENT_OPTIONS = [ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], { scope: "user,user:email"}]
GITHUB_ENABLED = GITHUB_CLIENT_OPTIONS.all?

SLACK_TEAM_NAME = ENV["SLACK_TEAM_NAME"]
SLACK_CLIENT_OPTIONS = [ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"]]
SLACK_ENABLED = SLACK_CLIENT_OPTIONS.all?

ESA_TEAM_NAME = ENV["ESA_TEAM_NAME"]
ESA_CLIENT_OPTIONS = [ENV["ESA_CLIENT_ID"], ENV["ESA_CLIENT_SECRET"]]
ESA_ENABLED = ESA_CLIENT_OPTIONS.all?

class App < Sinatra::Base
  use Rack::Protection::AuthenticityToken

  use OmniAuth::Builder do
    provider OmniAuth::Strategies::GoogleOauth2, *GOOGLE_CLIENT_OPTIONS
    provider OmniAuth::Strategies::GitHub, *GITHUB_CLIENT_OPTIONS if GITHUB_ENABLED
    provider OmniAuth::Strategies::Slack, *SLACK_CLIENT_OPTIONS if SLACK_ENABLED
    provider OmniAuth::Strategies::Esa, *ESA_CLIENT_OPTIONS if ESA_ENABLED
  end

  set :sessions, true
  set :session_secret, SESSION_SECRET

  def initialize(app = nil, **_kwargs)
    super
    @service = Service.new
  end

  helpers do
    def h(text)
      Rack::Utils.escape_html(text)
    end

    def current_user
      @current_user ||= session.dig(:user, :email) && @service.user(session[:user][:email])
    end

    def authenticity_token_tag
      %[<input type="hidden" name="authenticity_token" value="#{ h Rack::Protection::AuthenticityToken.token(env['rack.session']) }" />]
    end

    def link_url_tag(url)
      %[<a href="#{url}">#{url}</a>]
    end
  end

  before do
    @debug = params[:debug]
    next if request.path.start_with?("/auth/")
    next if request.path == "/login"
    next if current_user
    redirect "/login"
  end

  get "/" do
    erb :index
  end

  get "/users" do
    @users = @service.users.get.to_a
    erb :users
  end

  get "/login" do
    erb :login
  end

  get "/auth/google_oauth2/callback" do
    email = request.env["omniauth.auth"]["info"]["email"]
    user_ref = @service.users.doc(email)
    user_doc = user_ref.get
    google_info = {
      google: {
        uid: request.env["omniauth.auth"]["uid"],
        info: request.env["omniauth.auth"]["info"],
      }
    }
    if !user_doc.data || user_doc.data[:google][:uid] != request.env["omniauth.auth"]["uid"]
      user_ref.set(google_info)
    else
      user_ref.update(google_info)
    end
    session[:user] = {
      email: email,
    }
    redirect "/"
  end

  if GITHUB_ENABLED
    get "/auth/github/callback" do
      @service.users.doc(current_user.document_id).update({
        github: {
          uid: request.env["omniauth.auth"]["uid"],
          info: request.env["omniauth.auth"]["info"],
        }
      })
      redirect "/"
    end
  end

  if SLACK_ENABLED
    get "/auth/slack/callback" do
      @service.users.doc(current_user.document_id).update({
        slack: {
          uid: request.env["omniauth.auth"]["uid"],
          info: request.env["omniauth.auth"]["info"],
        }
      })
      redirect "/"
    end
  end

  if ESA_ENABLED
    get "/auth/esa/callback" do
      @service.users.doc(current_user.document_id).update({
        esa: {
          uid: request.env["omniauth.auth"]["uid"],
          info: request.env["omniauth.auth"]["info"],
        }
      })
      redirect "/"
    end
  end
end
