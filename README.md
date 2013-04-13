## Strava Suffer Management Chart

This script takes Strava suffer scores from your last 200 rides from a start date and creates a chart similar to but not exactly like:

* [TrainingPeaks Performance Management Chart](http://home.trainingpeaks.com/articles/cycling/what-is-the-performance-management-chart.aspx)
* [Fitness & Freshness Chart](http://blog.strava.com/new-premium-feature-fitness-freshness-for-power-meter-users-5742/)

The script produces a gnuplot that looks like:

![](https://raw.github.com/joewilliams/strava_suffer_mgmt/master/examples/2013-04-12_at_11.27.04_PM.png)

It'll also write a json file containing all the data:

    [
      {
        "startDateLocal": "2012-07-28T10:06:06Z",
        "ctl": 222.0,
        "atl": 222.0,
        "id": 15171785,
        "name": "East Side Death March",
        "tsb": 0.0,
        "sufferScore": 222
      },
      {
        "startDateLocal": "2012-07-29T16:48:51Z",
        "ctl": 125.1,
        "atl": 103.25,
        "id": 15419305,
        "name": "Colonnade Bike Practice",
        "tsb": 21.85,
        "sufferScore": 32
      }
    ]

Look in the examples dir for ... examples.

### Gem Dependencies

* yajl
* excon
* nokogiri
* gnuplot

### Usage

First edit the config file using your strava user id and desired start date

    $ $EDITOR config.json

Then run it

    $ ruby strava_suffer_mgmt.rb

After you run it once, you can run it again to plot the data you collected the last time

    $ ruby strava_suffer_mgmt.rb ./suffer_mgmt_data_1365834217.json


## License

Copyright 2013, Joe Williams <joe@joetify.com>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.