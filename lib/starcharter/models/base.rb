require 'starcharter'

module Starcharter

  ##
  # Methods for invoking Geocoder in a model.
  #
  module Model
    module Base

      def starcharter_options
        if defined?(@starcharter_options)
          @starcharter_options
        elsif superclass.respond_to?(:starcharter_options)
          superclass.starcharter_options || { }
        else
          { }
        end
      end

      def charted_by
        fail
      end

      def reverse_starcharter_by
        fail
      end

      private # ----------------------------------------------------------------

      def starcharter_init(options)
        unless @starcharter_options
          @starcharter_options = {}
          require "starcharter/stores/#{starcharter_file_name}"
          include Starcharter::Store.const_get(starcharter_module_name)
        end
        @starcharter_options.merge! options
      end
    end
  end
end

