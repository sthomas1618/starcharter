require 'starcharter/models/base'

module Starcharter
  module Model
    module ActiveRecord
      include Base

      ##
      # Set attribute names and include the Geocoder module.
      #
      def charted_by(x_attr, y_attr, options = {}, &block)
        starcharter_init(
          starcharter:       true,
          x:                 x_attr,
          y:                 y_attr,
          starcharter_block: block,
          units:             options[:units],
          method:            options[:method]
        )
      end

      ##
      # Set attribute names and include the Geocoder module.
      #
      # def reverse_geocoded_by(latitude_attr, longitude_attr, options = {}, &block)
      #   geocoder_init(
      #     :reverse_geocode => true,
      #     :fetched_address => options[:address] || :address,
      #     :latitude        => latitude_attr,
      #     :longitude       => longitude_attr,
      #     :reverse_block   => block,
      #     :units         => options[:units],
      #     :method        => options[:method]
      #   )
      # end


      private # --------------------------------------------------------------

      def starcharter_file_name;   "active_record"; end
      def starcharter_module_name; "ActiveRecord"; end
    end
  end
end