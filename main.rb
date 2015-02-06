require 'rubygems'
require 'sinatra'

get '/' do
  'Hello world!'
end


use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'asdfzxcvqwer' 




