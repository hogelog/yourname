require "sinatra/base"

class App < Sinatra::Base
  set :sessions, true
  set :foo, 'bar'

  get "/" do
    'Hello world!'
  end
end
