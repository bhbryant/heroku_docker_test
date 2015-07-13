require 'bundler/setup'
require 'goliath'

class Ps < Goliath::API
 
  def response(env)
    [200, {}, "<pre>#{`ps auxwww`}</pre>"]
  end
end