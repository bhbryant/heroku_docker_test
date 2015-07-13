require 'bundler/setup'
require 'goliath'

class Error < Goliath::API
 
  def response(env)
    raise "Ouch, Goliath!"
  end
end