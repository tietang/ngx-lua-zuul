

function d3_tsline(id, options) {

    var self = this;

    self.selector = id || "#chart";

    self.series = {};    // series objects
    self.ref_series = null; // default series to base calcs
    self.domain = {
        view_data:    { x: [0,0], y: [0,0] },
        data: { x: [0,0], y: [0,0] }
    };

    if(options === undefined || options === null) {
        options = self.defaults;
    }
    for(var k in self.defaults) {
        if(undefined === options[k]) {
            options[k] = self.defaults[k];
        }
    }

    self.width = options.width;
    self.height = options.height;
    self.summary_height = 50;
    self.handle_height = 14;
    self.summary_margin = 15;
    self.view_span = 64; // view_span (in data points)
    // buffer (in px) for showing a bit more y axis than min/max values
    self.y_nice_buffer = 2;
    self.orient_y = "right";
    self.interpolation = options.interpolation;
    self.tension = options.tension;

    self.scroll_view = true;
    self.scroll_interval = 1000; // in ms
    self.scrolling = false;

    self.show_summary = options.showSummary;
    self.fixed_y = null; // let y axis resize based on min/max of values
    //self.fixed_y = {min: 0-1, max: 100+1}; // fix y axis to 0-100

    // slider dimensions (in px)
    self.slider = {
        x: 729,
        w: 171,
        max_x: 729
    };

    // sizer values
    self.sizer_width = 9;
    self.left = { x: 0 };
    self.right = { x: 0 };

    //
    // functions
    //

    // ctor, called upon instantiation
    self.init = function() { };

    self.print_epoch = function(msg) {
        var time = (new Date()).valueOf();
        console.log(msg, time);
    };

    // override this to shape your data to what d3-tsline wants
    // which is [ [Date, value], [Date, value], ... ]
    self.format_data = function(data) {
        // this default implementation assumes data is in proper format already
        return data;
    };

    self.parse_date = function(dt) { return dt; }; // proper format already
    //self.parse_date = function(dt) { return new Date(dt*1000); }; // epoch
    //self.parse_date = function(dt) {
    //    d3.time.format("%b %d, %Y").parse(dt); // mon d, yyyy
    //}
    self.parse_val = function(val) { return val; };

    self.parse_point = function(pt) {
        pt[0] = self.parse_date(pt[0]);
        pt[1] = self.parse_val(pt[1]);
        return pt;
    };

    self.setSeriesData = function(id, data) {
        data = self.format_data(data);
        data.forEach(function(point) {
            point = self.parse_point(point);
        });
        self.series[id].data = data;
        if( self.show_summary ) self.set_domain("data");
    };

    // add a new point to each series, and redraw if update==true
    self.addSeriesPoints = function(points, update) {
        if( points ) {
            // calc the next x
            var one = self.one_series().data;
            var last_index = one.length - 1;
            var last_x = one[last_index][0].getTime();
            var x = (last_x + self.scroll_interval) / 1000;

            // build the points up in the series data arrays
            self.series_iter(function(id, elem) {
                var point;
                if( points[id] ) {
                    // we have a new value in next_pts
                    point = self.parse_point([ x, points[id] ]);
                } else {
                    // use previous point's value
                    point = self.parse_point(
                        [x, elem.data[elem.data.length-1][1] ]);
                }
                if( self.show_summary )
                    self.update_domain("data", point);
                elem.data.push(point);
            });
        }
        if( update ) self.draw_view();
        if( self.scrolling ) self.move_scroller();
    };

    // begin scrolling
    self.start_scroll = function() {
        self.scrolling = true;
        self.addSeriesPoints(self.next_pts, true);
    };

    // end scrolling
    self.stop_scroll = function() {
        self.scrolling = false;
        setTimeout(function() {
            clearTimeout(self.scroll_timer);
        }, self.timer_interval());
    };

    // scrolling mechanism... move svg:g element over to left
    self.move_scroller = function() {
        var diff = self.get_diff(self.width, "view_data");
        var tdiff = self.timer_interval();
        d3.select(self.selector + " .view .scroller")
            .attr("transform", "translate(" + 0 + ")")
            .transition()
            .ease("linear")
            .duration(self.scroll_interval)
            .attr("transform", "translate(" + -1 * diff + ", 0)");
        self.scroll_timer = setTimeout(function() {
            self.addSeriesPoints(self.next_pts, true);
        }, tdiff);

    };

    self.timer_interval = function() {
        var now = (new Date()).valueOf() / 1000;
        var diff = self.scroll_interval - ((now - now.toFixed(0)) * 1000);
        return Math.round(diff);
    };

    // calcs for view window and slider
    self.update_view_calcs = function() {

        var one = self.one_series();
        var max_elem = one.data.length - self.view_span;
        var start = 0, end = 0;

        if( self.show_summary ) {
            start = Math.round(self.slider.x * (max_elem / self.slider.max_x));
            end = start + self.view_span;
        } else {
            end = self.view_span;
            start = end - self.view_span;
        }

        if( self.scrolling ) start--;
        if( start < 0 ) start = 0;

        // make view window slice data arrays (one per series)
        self.series_iter(function(id, elem) {
	    elem.view_data = self.series[id].data.slice(start, end);
        });

        // note: this gets expensive for updates/renders as the view
        // dataset gets larger
        self.set_domain("view_data");

    };

    self.update_summary_calcs = function() {
        if( self.show_summary ) {
            var one = self.one_series();
            self.slider.w = Math.round(self.width *
                (self.view_span / one.data.length));
            self.slider.x = self.slider.max_x = self.width - self.slider.w
                - self.sizer_width/2;
            if( self.slider.x < 0 ) {
                self.slider.w = self.width;
                self.slider.x = self.slider.max_x = 0;
            }
        }
    };

    self.get_diff = function(w, type) {
        var one = self.one_series();
        return w / (one[type].length - 2);
    };

    self.render = function() {
        self.build_dom();
        self.draw_view();
        if( self.show_summary ) self.draw_summary();
    };

    self.build_dom = function() {

        d3.select(this.selector)
            .append("div")
            .attr("class", "view");
        if( self.show_summary ) {
            d3.select(this.selector)
                .append("div")
                .attr("class", "summary");
        }

        // VIEW dom elements

        var view = d3.select(this.selector + " .view");
        view.selectAll("*").remove();

        // Add an SVG element with the desired dimensions and margin.
        var svg = view.append("svg:svg")
            .attr("width", self.width)
            .attr("height", self.height);

        // draw scroller group, with x axis and data line(s)

        // remove old
        svg.selectAll(".scroller").remove();

        var scroller = svg.append("svg:g")
            .attr("class", "scroller");

        // Add the x-axis.
        scroller.append("svg:g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + (self.height - 15) + ")");

        // Add the line paths (one per series)
        self.series_iter(function(id, elem) {
            if( elem.active ) {
                var path = scroller.append("svg:path")
                    .attr("class", "line s_" + id);
                elem.path = path;
            }
        });

        // Add the y-axis.
        svg.append("svg:g")
            .attr("class", "y axis");


        // SUMMARY dom elements
        if( self.show_summary ) {
            var summary = d3.select(self.selector + " .summary");
            var w=self.width, h=self.summary_height, m=self.summary_margin;

            // Add an SVG element with the desired dimensions and margin.
            svg = summary.append("svg:svg")
                .attr("width", w)
                .attr("height", h + self.handle_height + 1);
            var g = svg.append("svg:g")
                .attr("class", "lines")
                .attr("transform", "translate(" + m + ")");


            // Add the border.
            g.append("svg:rect")
                .attr("class", "border")
                .attr("x", 0)
                .attr("y", 1)
                .attr("width", w - 2*m)
                .attr("height", h);

            // Add top border
            g.append("svg:line")
                .attr("class", "top_border")
                .attr("y1", 1)
                .attr("y2", 1)
                .attr("x1", -1 * m)
                .attr("x2", w - m);

            // Add the line paths (one per series)
            self.series_iter(function(id, elem) {
                if( elem.active ) {
                    var path = g.append("svg:path")
                        .attr("class", "line summary s_" + id);
                    elem.summary_path = path;
                }
            });

            // Add the x-axis.
            g.append("svg:g")
                .attr("class", "x axis summary")
                .attr("transform", "translate(0," + (h - 15) + ")");

            // Add the y-axis.
            g.append("svg:g")
                .attr("class", "y axis summary");


            // SLIDER dom elements

            var sizer_w = self.sizer_width,
            sizer_halfw = Math.floor(sizer_w/2),
            sizer_h = Math.round(self.summary_height / 3);

            // slider_container
            var slider_container = svg.append("svg:g")
                .append("svg:g")
                .attr("class", "slider_container");

            // slider
            var slider = svg.append("svg:g")
                .attr("class", "slider");

            // left border and sizer
            var left = slider_container.append("svg:g")
                .attr("class", "left");

            left.append("svg:line")
                .attr("y1", 1)
                .attr("y2", self.summary_height)
                .attr("x1", 0)
                .attr("x2", 0)
                .attr("class", "border");

            left.append("svg:rect")
                .attr("class", "sizer")
                .attr("x", -1 * sizer_halfw)
                .attr("y", Math.round(self.summary_height/2)-Math.round(sizer_h/2))
                .attr("width", sizer_w)
                .attr("height", sizer_h)
                .attr("rx", 2)
                .attr("ry", 2)

            // right border and sizer
            var right = slider_container.append("svg:g")
                .attr("class", "right");
            self.right.x = self.slider.w;

            right.append("svg:line") // summary right border
                .attr("y1", 1)
                .attr("y2", self.summary_height)
                .attr("x1", sizer_w - 2)
                .attr("x2", sizer_w - 2)
                .attr("class", "border");

            right.append("svg:rect")
                .attr("class", "sizer")
                .attr("x", sizer_w - sizer_halfw - 2)
                .attr("y", Math.round(self.summary_height/2)-Math.round(sizer_h/2))
                .attr("width", sizer_w)
                .attr("height", sizer_h)
                .attr("rx", 2)
                .attr("ry", 2)

            // slider top 'clear'  border
            slider_container.append("svg:line")
                .attr("class", "slider-top-border")
                .attr("y1", 1)
                .attr("y2", 1)
                .attr("x1", 1)
                .attr("x2", self.slider.w - sizer_w - 2);

            // bottom handle
            var handle_w = self.slider.w - sizer_w - 2;
            var handle = slider.append("svg:rect")
                .attr("class", "handle bottom")
                .attr("x", 0)
                .attr("y", self.summary_height)
                .attr("width", handle_w)
                .attr("height", self.handle_height);

            // raised ridges
            var rt = Math.round(self.handle_height / 2) - 3 +
                self.summary_height;
            var rl = Math.round(handle_w / 2) - 4;
            var ridges = slider.append("svg:g")
                .attr("class", "ridges")
                .attr("transform", "translate(" + rl + ")");
            for( var i=0; i < 4; i++ ) {
                ridges.append("svg:line")
                    .attr("class", "handle-ridges odd")
                    .attr("y1", rt)
                    .attr("y2", rt + 5)
                    .attr("x1", (i*2))
                    .attr("x2", (i*2));

                ridges.append("svg:line")
                    .attr("class", "handle-ridges even")
                    .attr("y1", rt + 1)
                    .attr("y2", rt + 6)
                    .attr("x1", (i*2) + 1)
                    .attr("x2", (i*2) + 1);
            }

            // dragging
            slider.call(d3.behavior.drag()
                        .on("dragstart", function(d) {
                            this.__origin__ = self.slider.x;
                            this.__offset__ = 0;
                        })
                        .on("drag", function(d) {
                            this.__offset__ += d3.event.dx;
                            self.move_slider(this.__origin__, this.__offset__);
                        })
                        .on("dragend", function() {
                            delete this.__origin__;
                            delete this.__offset__;
                        }));

            // dragging on left/right sizers
            var sizer_spec = d3.behavior.drag()
                .on("dragstart", function(d) {
                    var clazz = this.className.baseVal;
                    console.log("sizer_spec class: ", clazz, this);
                    this.__origin__ = self[clazz].x;
                    this.__offset__ = 0;
                })
                .on("drag", function(d) {
                    this.__offset__ += d3.event.dx;
                    self.move_sizer(this);
                })
                .on("dragend", function() {
                    delete this.__origin__;
                    delete this.__offset__;
                    self.sizer_end(this);
                });
            left.call(sizer_spec);
            right.call(sizer_spec);


        }
        else {
            // todo: we miss bottom border here when not drawing summary            
        }
    };

    self.activate_series = function(series) {
        if( self.series[series] && !self.series[series].active ) {

            // view path
            var path = d3.select(self.selector + " .view .scroller")
                .append("svg:path")
                .attr("class", "line s_" + series);
            self.series[series].path = path;

            // summary path
            if( self.show_summary ) {
                var path = d3.select(self.selector + " .summary .lines")
                    .append("svg:path")
                    .attr("class", "line summary s_" + series);
                self.series[series].summary_path = path;
            }

            // active attrib
            self.series[series].active = true;

        }
    };

    self.deactivate_series = function(series) {
        if( self.series[series] ) {

            // view path
            d3.selectAll(self.selector + " .view .scroller path.s_" + series)
                .remove();
            self.series[series].path = null;

            // summary path
            if( self.show_summary ) {
                d3.selectAll(self.selector + " .summary .lines path.s_"+series)
                    .remove()
                self.series[series].summary_path = null;
            }

            // active attrib
            self.series[series].active = false;

        }
    };

    // if we have fewer data points than self.view_span, fill in data to left
    // so the chart seems to start from the right and scroll left
    self.fill_left_pts = function(interval, fill_value, seed_x) {

        // handle when no data set, make blank series data for each series
        self.series_iter(function(id, elem) {
            if( !elem.data ) elem.data = [];
        });

        var one = self.one_series();
        var len = one.data.length;
        var min_x;
        try {
            min_x = one[0][0];
        } catch(e) {
            min_x = seed_x;
        }
        if( self.scrolling ) min_x--;

        var date, value;
        for( var i = min_x - 1;
             i >= (min_x - (self.view_span - len) - 1);
             i = i - interval ) {
            self.series_iter(function(id, elem) {
                date = self.parse_date(i);
                value = self.parse_val(fill_value) || null;
                elem.data.unshift([date,value]);
            });
        }
    };

    // set min/max values for x & y
    // loops through all data, so try not to run except during graph init
    self.set_domain = function(type) {

        var xMin = 0, xMax = 0, yMin = 0, yMax = 0;

        var data = self.one_series()[type];
        if( data && data[0] ) {
            // get x min/max from the 'one' series
	    xMin = data[0][0];
	    xMax = data[ data.length - 1 ][0];

            if( !self.fixed_y ) {
                // get all y values from all series
	        var values = [];
	        self.series_iter(function(id, elem) {
                    if( elem.active ) {
                        elem[type].forEach(function(d) {
		            values.push( d[1] );
	                });
                    }
	        });

                // get y min/max from values array built above
	        yMin = d3.min( values ) - self.y_nice_buffer;
	        yMax = d3.max( values ) + self.y_nice_buffer;
            } else {
                yMin = self.fixed_y.min;
                yMax = self.fixed_y.max;
            }
        }
	self.domain[type] = {
            x: [xMin, xMax],
            y: [yMin, yMax]
        };
    };

    self.update_domain = function(type, point) {
        // min x
        if( point[0] < self.domain[type].x[0] )
            self.domain[type].x[0] = point[0];
        // max x
        if( point[0] > self.domain[type].x[1] )
            self.domain[type].x[1] = point[0];
        // min y
        if( point[1] < self.domain[type].y[0] )
            self.domain[type].y[0] = point[1];
        // max y
        if( point[1] > self.domain[type].y[1] )
            self.domain[type].y[1] = point[1];
    };

    // draw the top view pane (by updating dom elems/attrs)
    self.draw_view = function() {

        var w = self.width, range_w = self.width, h = self.height;

        // get view data set
        self.update_view_calcs();

        // set up scale and axis functions

        // if we are scrolling, add overflow point to right
        if( self.scrolling ) {
            var diff = self.get_diff(w, "view_data");
            range_w = w + diff;
        }

        var x = d3.time.scale()
            .range([0, range_w])
            .domain(self.domain.view_data.x);
        var y = d3.scale.linear()
            .range([h, 0])
            .domain(self.domain.view_data.y).nice();
        xAxis = d3.svg.axis()
            .scale(x)
            .tickSize(-1 * h)
	    .ticks(10)
	    .orient("bottom");
            //.tickSubdivide(false);
        yAxis = d3.svg.axis()
            .scale(y)
            .ticks(5)
            .tickSize(5)
            .orient(self.orient_y);

        // A line generator, for the dark stroke.
        var line = d3.svg.line()
            .x( function(d) { return x(d[0]) })
            .y( function(d) { return y(d[1]) })
            .interpolate(self.interpolation).tension(self.tension);

        var view = d3.select(this.selector + " .view");

        // update x axis
        view.select(".x.axis").call(xAxis);

        // update the line paths (one per series)
        self.series_iter(function(id, elem) {
            if( elem.active && elem.path ) {
                elem.path
                    .data([elem.view_data])
                    .attr("d", line);
            }
        });

        // update y axis
        view.select(".y.axis").call(yAxis);
    };

    self.draw_summary = function() {

        var w = self.width, h = self.summary_height, m = self.summary_margin;

        // get summary data set
        self.update_summary_calcs();

        // set up scale and axis functions
        var x = d3.time.scale()
            .range([1, w - 2*m])
            .domain(self.domain.data.x);
        var y = d3.scale.linear()
            .range([h, 0])
            .domain(self.domain.data.y).nice();
        xAxis = d3.svg.axis()
            .scale(x)
	    .ticks(4)
            .tickSize(-1 * h)
            .tickSubdivide(false);
        yAxis = d3.svg.axis()
            .scale(y)
            .ticks(2)
            .tickSize(5)
            .orient(self.orient_y);

        // A line generator, for the dark stroke.
        var line = d3.svg.line()
            .x( function(d) { return x(d[0]) })
            .y( function(d) { return y(d[1]) })
            .interpolate(self.interpolation).tension(self.tension);

        var summary = d3.select(this.selector + " .summary");

        // update x axis
        summary.select(".x.axis.summary").call(xAxis);

        // update the line paths (one per series)
        self.series_iter(function(id, elem) {
            if( elem.active && elem.summary_path) {
                elem.summary_path
                    .data([elem.data])
                    .attr("d", line);
            }
        });

        // update y axis
        summary.select(".y.axis.summary").call(yAxis);

        self.draw_slider()
    };

    self.draw_slider = function() {

        console.log("draw_slider");

        var sizer_w = self.sizer_width;
        var handle_w = self.slider.w - sizer_w - 2;
        var rl = Math.round(handle_w / 2) - 4;

        var container = d3.select(this.selector + " .slider_container");
        container.attr("transform",
                       "translate(" + (self.slider.x + 1) + ")");

        var slider = d3.select(this.selector + " .slider");
        slider.attr("transform",
                    "translate(" + (self.slider.x + 1) + ")");

        var left = container.select(".left");
        left.attr("transform", "translate(0)");

        var right = container.select(".right");
        var right_x = self.slider.w - sizer_w*2;
        right.attr("transform",
                   "translate(" + right_x + ")");
        var slider_top_border = container.select(".slider-top-border");
        slider_top_border.attr("x2", self.slider.w - sizer_w - 2);

        var handle = slider.select(".handle.bottom");
        handle.attr("width", handle_w);

        var ridges = slider.select(".ridges");
        ridges.attr("transform", "translate(" + rl+ ")");
    };

    self.move_slider = function(origin, dx) {
        var sizer_w = self.sizer_width;
        var m = self.summary_margin;

        self.slider.x = origin + dx;
        if( self.slider.x < m ) self.slider.x = m;
        if( self.slider.x > self.slider.max_x)
            self.slider.x = self.slider.max_x;
        d3.select(this.selector + " .slider_container")
            .attr("transform", "translate(" + self.slider.x + ")")
        var slider_new_x = self.slider.x;
        d3.select(this.selector + " .slider")
            .attr("transform", "translate(" + slider_new_x + ")")
        self.draw_view();
    };

    self.move_sizer = function(sizer) {
        var clazz = sizer.className.baseVal;
        //console.log(clazz, self.left.x, self.right.x);
        self[clazz].x = sizer.__origin__ + sizer.__offset__;
        d3.select(this.selector + " ." + clazz)
            .attr("transform", "translate(" + self[clazz].x + ")")
    };

    self.sizer_end = function(sizer) {
        var clazz = sizer.className.baseVal;
        var diffpx = self[clazz].x;
        var one = self.one_series();
        // px to data points
        var diff = Math.round(diffpx * (one.data.length / self.width));
        console.log("data.length", one.data.length);
        console.log("self.width", self.width);
        console.log("self.view_span old", self.view_span);
        console.log("diffpx", diffpx);
        console.log("diff", diff);
        if( clazz == "left" ) {
            self.slider.x += diffpx;
            self.view_span -= diff;
        } else {
            self.view_span += diff;
        }
        console.log("self.view_span new", self.view_span);
        // reset sizer x
        self[clazz].x = 0;

        // recalc and redraw
        self.update_summary_calcs();
        self.draw_view();
        self.draw_slider();
    };

    self.destroy = function() {
        self.stop_scroll();
        d3.select(self.selector + " .view, " + self.selector + " .summary")
            .remove();
    };

    // used for operations that need only one series, maybe to get x values
    self.one_series = function() {
        if( self.ref_series )
            return self.series[self.ref_series];
        throw "ref_series not set?";
    };

    self.series_iter = function(fun, limit) {
        var i=0;
        for( var id in self.series ) {
            if( self.series.hasOwnProperty(id) ) {
                fun(id, self.series[id]);
            }
            if( i++ >= limit ) break;
        }
    };

    // call constructor (after all functions have been loaded)
    self.init();

};

// default settings that can be specifically overriden by passing options argument
d3_tsline.prototype.defaults = {
    width: 1000                   // width of the chart
    , height: 400                 // height of the chart
    , tension: 0.8                // tension for lines: https://github.com/mbostock/d3/wiki/SVG-Shapes#wiki-line_tension
    , interpolation: "cardinal"   // interpolation for lines: https://github.com/mbostock/d3/wiki/SVG-Shapes#wiki-line_interpolate
    , showSummary: true           // displays scrollable summary
};