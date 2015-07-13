require 'bundler/setup'
require 'goliath'

class Hello < Goliath::API
 
  def response(env)
    puts "HERE"
    [200, {}, "Hello, Goliath!"]
  end
end