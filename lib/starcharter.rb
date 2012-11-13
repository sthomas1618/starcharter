require "starcharter/configuration"
require "starcharter/query"
require "starcharter/calculations"
require "starcharter/exceptions"
require "starcharter/cache"
require "starcharter/request"
require "starcharter/lookup"
require "starcharter/models/active_record" if defined?(::ActiveRecord)
require "starcharter/models/mongoid" if defined?(::Mongoid)
require "starcharter/models/mongo_mapper" if defined?(::MongoMapper)

module Starcharter
  extend self

  ##
  # Search for information about an address or a set of coordinates.
  #
  def search(query, options = {})
    query = Starcharter::Query.new(query, options) unless query.is_a?(Starcharter::Query)
    query.blank? ? [] : query.execute
  end

  ##
  # Look up the coordinates of the given street or IP address.
  #
  def coordinates(address, options = {})
    if (results = search(address, options)).size > 0
      results.first.coordinates
    end
  end

  ##
  # Look up the address of the given coordinates ([lat,lon])
  # or IP address (string).
  #
  def address(query, options = {})
    if (results = search(query, options)).size > 0
      results.first.address
    end
  end

  ##
  # The working Cache object, or +nil+ if none configured.
  #
  def cache
    if @cache.nil? and store = Configuration.cache
      @cache = Cache.new(store, Configuration.cache_prefix)
    end
    @cache
  end
end

# load Railtie if Rails exists
if defined?(Rails)
  require "starcharter/railtie"
  Starcharter::Railtie.insert
end
