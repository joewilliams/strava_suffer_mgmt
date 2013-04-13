#! /usr/bin/env ruby

## This code is available as Open Source Software under the MIT license.
##
## Copyright 2013, Joe Williams <joe@joetify.com>
##
## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use,
## copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the
## Software is furnished to do so, subject to the following
## conditions:
##
## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
## OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
## HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
## WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
## OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'yajl/json_gem'
require 'excon'
require 'uri'
require 'nokogiri'
require 'gnuplot'

STRAVA_URL = 'http://www.strava.com'
STRAVA_API = "api/v1"

ATL_DAYS = 7.0
CTL_DAYS = 42.0

# best guesses
ATL_ALPHA = 0.75
CTL_ALPHA = 0.98

def rate(alpha, rate, total, interval)
  instant = total / interval
  new_rate = rate + (alpha * (instant - rate))
  new_rate
end

def update_total(total, value)
  total + value
end

def list_sum(list)
  list.inject{|sum,x| sum + x }
end

def ewma(alpha, interval, current_rate, values)
  if values.length >= interval
    values.shift
  end

  values = values << current_rate

  total = list_sum(values)

  current_atl = rate(alpha, current_rate, total, values.length)

  {"values" => values, "rate" => current_atl}
end

def get_rides(athlete_id, start_date)
  rides = []

  # get last 200 rides
  [0, 50, 100, 150].each do |offset|
    response = Excon.get(URI.escape("#{STRAVA_URL}/#{STRAVA_API}/rides?athleteId=#{athlete_id}&startDate=#{start_date}&offset=#{offset}"))
    data = JSON.parse(response.body)["rides"]
    rides = rides + data
  end

  rides.reverse
end

def plot(suffer_rides)
  atl_series = []
  ctl_series = []
  tsb_series = []

  # get the stuff we want to plot
  suffer_rides.each do |ride|
    atl_series << ride["atl"]
    ctl_series << ride["ctl"]
    tsb_series << ride["tsb"]
  end

  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|

      plot.title  "suffer mgmt chart"

      x = (1..atl_series.length).collect { |v| v.to_f }
      zero = x.collect { |v| v * 0 }

      plot.data = [
        Gnuplot::DataSet.new( [x, atl_series] ) { |ds|
          ds.with = "linespoints"
          ds.title = "atl"
          ds.linecolor = "rgb \"green\""
        },
        Gnuplot::DataSet.new( [x, ctl_series] ) { |ds|
          ds.with = "linespoints"
          ds.title = "ctl"
          ds.linecolor = "rgb \"red\""
        },
        Gnuplot::DataSet.new( [x, tsb_series] ) { |ds|
          ds.with = "linespoints"
          ds.title = "tsb"
          ds.linecolor = "rgb \"blue\""
        },
        Gnuplot::DataSet.new( [x, zero] ) { |ds|
          ds.with = "lines"
          ds.title = "zero"
          ds.linecolor = "rgb \"black\""
        }
      ]

    end
  end
end

def get_suffer_score(ride_id)
  suffer_score = nil

  # first lets get the suffer scores by abusing public activity pages
  doc = Nokogiri::HTML(Excon.get(URI.escape("#{STRAVA_URL}/activities/#{ride_id}")).body)

  # hacky but it works
  if doc.at_css('.suffer-score')
    doc.at_css('.suffer-score').children.each do |kid|
      if kid.children
        if kid.children.text
          if kid.children.text.to_i > 0
             suffer_score = kid.children.text.to_i
          end
        end
      end
    end
  end

  suffer_score
end

def get_ride_date(ride_id)
  response = Excon.get(URI.escape("#{STRAVA_URL}/#{STRAVA_API}/rides/#{ride_id}"))
  JSON.parse(response.body)["ride"]["startDateLocal"]
end

def read_json(file)
  json = File.read(file)
  data = JSON.parse(json)
  data
end

def write_json(data)
  json = JSON.pretty_generate(data)
  File.open("./suffer_mgmt_data_#{Time.now.to_i}.json", 'w') {|f| f.write(json) }
end

def main()
  if ARGV[0]
    data = read_json(ARGV[0])
    plot(data)
  else
    atl = {"values" => []}
    ctl = {"values" => []}

    suffer_rides = []

    # read the config
    config = read_json("./config.json")

    # ask the api for all the rides
    rides =  get_rides(config["athlete_id"], config["start_date"])

    rides.each do |ride|

      # get the suffer score
      suffer_score = get_suffer_score(ride["id"])

      if suffer_score
        # store the suffer score
        ride.store("sufferScore", suffer_score)

        # since the activity has a suffer score now lets get the date
        date = get_ride_date(ride["id"])
        ride.store("startDateLocal", date)

        # use the computer to calculate ewma's of your suffer scores
        atl = ewma(ATL_ALPHA, ATL_DAYS, ride["sufferScore"], atl["values"])
        ctl = ewma(CTL_ALPHA, CTL_DAYS, ride["sufferScore"], ctl["values"])

        ride.store("atl", atl["rate"])
        ride.store("ctl", ctl["rate"])
        ride.store("tsb", ctl["rate"] - atl["rate"])

        suffer_rides << ride
      end
    end

    plot(suffer_rides)
    write_json(suffer_rides)
  end
end

main
