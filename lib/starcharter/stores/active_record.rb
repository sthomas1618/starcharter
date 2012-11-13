require 'starcharter/sql'
require 'starcharter/stores/base'

##
# Add starcharting functionality to any ActiveRecord object.
#
module Starcharter::Store
  module ActiveRecord
    include Base

    ##
    # Implementation of 'included' hook method.
    #
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        # scope: geocoded objects
        scope :starcharted, lambda {
          {:conditions => "#{starcharter_options[:y]} IS NOT NULL " +
            "AND #{starcharter_options[:x]} IS NOT NULL"}}

        # scope: not-geocoded objects
        scope :not_starcharted, lambda {
          {:conditions => "#{starcharter_options[:y]} IS NULL " +
            "OR #{starcharter_options[:x]} IS NULL"}}

        ##
        # Find all objects within a radius of the given location.
        # Location may be either a string to geocode or an array of
        # coordinates (<tt>[lat,lon]</tt>). Also takes an options hash
        # (see Geocoder::Orm::ActiveRecord::ClassMethods.near_scope_options
        # for details).
        #
        scope :near, lambda{ |location, *args|
          x, y = Starcharter::Calculations.extract_coordinates(location)
          if Starcharter::Calculations.coordinates_present?(x, y)
            near_scope_options(x, y, *args)
          else
            # If no lat/lon given we don't want any results, but we still
            # need distance and bearing columns so you can add, for example:
            # .order("distance")
            select(select_clause(nil, "NULL", "NULL")).where(false_condition)
          end
        }

        ##
        # Find all objects within the area of a given bounding box.
        # Bounds must be an array of locations specifying the southwest
        # corner followed by the northeast corner of the box
        # (<tt>[[sw_lat, sw_lon], [ne_lat, ne_lon]]</tt>).
        #
        scope :within_bounding_box, lambda{ |bounds|
          sw_x, sw_y, ne_x, ne_y = bounds.flatten if bounds
          if sw_x && sw_y && ne_x && ne_y
            {:conditions => Starcharter::Sql.within_bounding_box(
              sw_x, sw_y, ne_x, ne_y,
              full_column_name(starcharter_options[:x]), 
              full_column_name(starcharter_options[:y])
            )}
          else
            select(select_clause(nil, "NULL", "NULL")).where(false_condition)
          end
        }
      end
    end

    ##
    # Methods which will be class methods of the including class.
    #
    module ClassMethods

      def distance_from_sql(location, *args)
        x, y = Starcharter::Calculations.extract_coordinates(location)
        if Starcharter::Calculations.coordinates_present?(x, y)
          distance_sql(x, y, *args)
        end
      end

      private # ----------------------------------------------------------------

      ##
      # Get options hash suitable for passing to ActiveRecord.find to get
      # records within a radius (in kilometers) of the given point.
      # Options hash may include:
      #
      # * +:units+   - <tt>:mi</tt> or <tt>:km</tt>; to be used.
      #   for interpreting radius as well as the +distance+ attribute which
      #   is added to each found nearby object.
      #   See Geocoder::Configuration to know how configure default units.
      # * +:bearing+ - <tt>:linear</tt> or <tt>:spherical</tt>.
      #   the method to be used for calculating the bearing (direction)
      #   between the given point and each found nearby point;
      #   set to false for no bearing calculation.
      #   See Geocoder::Configuration to know how configure default method.
      # * +:select+  - string with the SELECT SQL fragment (e.g. “id, name”)
      # * +:order+   - column(s) for ORDER BY SQL clause; default is distance;
      #                set to false or nil to omit the ORDER BY clause
      # * +:exclude+ - an object to exclude (used by the +nearbys+ method)
      #
      def near_scope_options(x, y, radius = 20, options = {})
        options[:units] ||= (starcharter_options[:units] || Starcharter::Configuration.units)
        bearing = bearing_sql(x, y, options)
        distance = distance_sql(x, y, options)

        b = Starcharter::Calculations.bounding_box([x, y], radius, options)
        args = b + [
          full_column_name(starcharter_options[:x]),
          full_column_name(starcharter_options[:y])
        ]
        bounding_box_conditions = Starcharter::Sql.within_bounding_box(*args)

        if using_sqlite?
          conditions = bounding_box_conditions
        else
          conditions = [bounding_box_conditions + " AND #{distance} <= ?", radius]
        end
        {
          :select => select_clause(options[:select], distance, bearing),
          :conditions => add_exclude_condition(conditions, options[:exclude]),
          :order => options.include?(:order) ? options[:order] : "distance ASC"
        }
      end

      ##
      # SQL for calculating distance based on the current database's
      # capabilities (trig functions?).
      #
      def distance_sql(x, y, options = {})
        method_prefix = using_sqlite? ? "approx" : "full"
        Starcharter::Sql.send(
          method_prefix + "_distance",
          x, y,
          full_column_name(starcharter_options[:x]),
          full_column_name(starcharter_options[:y]),
          options
        )
      end

      ##
      # SQL for calculating bearing based on the current database's
      # capabilities (trig functions?).
      #
      def bearing_sql(x, y, options = {})
        if !options.include?(:bearing)
          options[:bearing] = Starcharter::Configuration.distances
        end
        if options[:bearing]
          method_prefix = using_sqlite? ? "approx" : "full"
          Starcharter::Sql.send(
            method_prefix + "_bearing",
            x, y,
            full_column_name(starcharter_options[:x]),
            full_column_name(starcharter_options[:y]),
            options
          )
        end
      end

      ##
      # Generate the SELECT clause.
      #
      def select_clause(columns, distance = nil, bearing = nil)
        if columns == :id_only
          return full_column_name(primary_key)
        elsif columns == :geo_only
          clause = ""
        else
          clause = (columns || full_column_name("*")) + ", "
        end
        clause + "#{distance} AS distance" +
          (bearing ? ", #{bearing} AS bearing" : "")
      end

      ##
      # Adds a condition to exclude a given object by ID.
      # Expects conditions as an array or string. Returns array.
      #
      def add_exclude_condition(conditions, exclude)
        conditions = [conditions] if conditions.is_a?(String)
        if exclude
          conditions[0] << " AND #{full_column_name(primary_key)} != ?"
          conditions << exclude.id
        end
        conditions
      end

      def using_sqlite?
        connection.adapter_name.match /sqlite/i
      end

      ##
      # Value which can be passed to where() to produce no results.
      #
      def false_condition
        using_sqlite? ? 0 : "false"
      end

      ##
      # Prepend table name if column name doesn't already contain one.
      #
      def full_column_name(column)
        column = column.to_s
        column.include?(".") ? column : [table_name, column].join(".")
      end
    end

    ##
    # Look up coordinates and assign to +latitude+ and +longitude+ attributes
    # (or other as specified in +geocoded_by+). Returns coordinates (array).
    #
    def geocode
      do_lookup(false) do |o,rs|
        if r = rs.first
          unless r.latitude.nil? or r.longitude.nil?
            o.__send__  "#{self.class.starcharter_options[:latitude]}=",  r.latitude
            o.__send__  "#{self.class.starcharter_options[:longitude]}=", r.longitude
          end
          r.coordinates
        end
      end
    end

    alias_method :fetch_coordinates, :geocode

    ##
    # Look up address and assign to +address+ attribute (or other as specified
    # in +reverse_geocoded_by+). Returns address (string).
    #
    def reverse_geocode
      do_lookup(true) do |o,rs|
        if r = rs.first
          unless r.address.nil?
            o.__send__ "#{self.class.starcharter_options[:fetched_address]}=", r.address
          end
          r.address
        end
      end
    end

    alias_method :fetch_address, :reverse_geocode
  end
end

