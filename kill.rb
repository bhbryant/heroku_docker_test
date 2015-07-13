require 'bundler/setup'
require 'goliath'

class Kill < Goliath::API

  use Goliath::Rack::Params
 
  def response(env)
    [200, {}, "<pre>#{`kill -s 9 #{params["pid"]}`}</pre>"]
  end
end