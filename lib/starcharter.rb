require "starcharter/configuration"
#require "starcharter/query"
require "starcharter/calculations"
require "starcharter/exceptions"
#require "starcharter/cache"
#require "starcharter/request"
#require "starcharter/lookup"
require "starcharter/models/active_record" if defined?(::ActiveRecord)
require "starcharter/models/mongoid" if defined?(::Mongoid)
require "starcharter/models/mongo_mapper" if defined?(::MongoMapper)

module Starcharter
  extend self

end

# load Railtie if Rails exists
if defined?(Rails)
  require "starcharter/railtie"
  Starcharter::Railtie.insert
end
