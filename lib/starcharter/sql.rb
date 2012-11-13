module Starcharter
  module Sql
    extend self

    ##
    # Distance calculation for use with a database that supports POWER(),
    # SQRT(), PI(), and trigonometric functions SIN(), COS(), ASIN(),
    # ATAN2(), DEGREES(), and RADIANS().
    #
    # Based on the excellent tutorial at:
    # http://www.scribd.com/doc/2569355/Geo-Distance-Search-with-MySQL
    #
    def full_distance(pos_x, pos_y, x_attr, y_attr, options = {})
      "POWER(POWER(#{pos_x} - #{x_attr}) + (#{pos_y} + #{y_attr}))"
    end

    ##
    # Distance calculation for use with a database without trigonometric
    # functions, like SQLite. Approach is to find objects within a square
    # rather than a circle, so results are very approximate (will include
    # objects outside the given radius).
    #
    # Distance and bearing calculations are *extremely inaccurate*. To be
    # clear: this only exists to provide interface consistency. Results
    # are not intended for use in production!
    #
    def approx_distance(x, y, x_attr, y_attr, options = {})

      # sin of 45 degrees = average x or y component of vector
      factor = Math.sin(Math::PI / 4)

      "(ABS(#{x_attr} - #{x.to_f}) * #{factor}) + " +
        "(ABS(#{x_attr} - #{y.to_f}) * #{factor})"
    end

    def within_bounding_box(sw_x, sw_y, ne_x, ne_y, x_attr, y_attr)
      spans = "#{y_attr} BETWEEN #{sw_y} AND #{ne_y} AND "
      spans + "#{x_attr} BETWEEN #{sw_x} AND #{ne_x}"
    end

    ##
    # Fairly accurate bearing calculation. Takes a latitude, longitude,
    # and an options hash which must include a :bearing value
    # (:linear or :spherical).
    #
    # Based on:
    # http://www.beginningspatial.com/calculating_bearing_one_point_another
    #
    def full_bearing(x, y, x_attr, y_attr, options = {})
      case options[:bearing]
        # DECLARE @Bearing DECIMAL(18,15)
        # DECLARE @dx FLOAT = @Point2.STX - @Point1.STX
        # DECLARE @dy FLOAT = @Point2.STY - @Point1.STY
        # IF (@Point1.STEquals(@Point2) = 1)
        #   SET @Bearing = NULL
        # ELSE
        #   SET @Bearing = ATN2(@dx,@dy)
        #   SET @Bearing = (DEGREES(@Bearing) + 360) % 360
        # RETURN @Bearing
      when :linear
        "CAST(" +
          "DEGREES(ATAN2( " +
            "#{x_attr} - #{x.to_f}, " +
            "#{y_attr} - #{y.to_f}" +
          ")) + 360 " +
        "AS decimal) % 360"
      when :spherical
        "CAST(" +
          "DEGREES(ATAN2( " +
            "SIN(#{x_attr} - #{x.to_f}) * " +
            "COS(#{y_attr}), (" +
              "COS(#{y.to_f}) * SIN(#{y_attr})" +
            ") - (" +
              "SIN(#{y.to_f}) * COS(#{y_attr}) * " +
              "COS(#{x_attr} - #{x.to_f}))" +
            ")" +
          ")) + 360 " +
        "AS decimal) % 360"
      end
    end

    ##
    # Totally lame bearing calculation. Basically useless except that it
    # returns *something* in databases without trig functions.
    #
    def approx_bearing(x, y, x_attr, y_attr, options = {})
      "CASE " +
        "WHEN (#{y_attr} >= #{y.to_f} AND " +
          "#{x_attr} >= #{x.to_f}) THEN  45.0 " +
        "WHEN (#{y_attr} <  #{y.to_f} AND " +
          "#{x_attr} >= #{x.to_f}) THEN 135.0 " +
        "WHEN (#{y_attr} <  #{y.to_f} AND " +
          "#{x_attr} <  #{x.to_f}) THEN 225.0 " +
        "WHEN (#{y_attr} >= #{y.to_f} AND " +
          "#{x_attr} <  #{x.to_f}) THEN 315.0 " +
      "END"
    end
  end
end
