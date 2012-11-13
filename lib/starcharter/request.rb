require 'starcharter'

module Starcharter
  module Request

    def location
      unless defined?(@location)
        @location = Starcharter.search(ip).first
      end
      @location
    end
  end
end

if defined?(Rack) and defined?(Rack::Request)
  Rack::Request.send :include, Starcharter::Request
end
