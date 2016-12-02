function GetRandomNum(Min,Max)
{
var Range = Max - Min;
var Rand = Math.random();
return(Min + Math.round(Rand * Range));
}


// initial values
var start = (new Date().getTime())

// chart instantiation
var chart = new d3_tsline("#chart");
chart.show_summary = false;
chart.fixed_y = {min: 0-1, max: 100+1}; // fix y axis to 0-100
chart.parse_date = function(dt) {
    // we use seconds, Date uses millis
    return new Date(dt*1000);
};
chart.view_span = 20; // show 20 secs by default
chart.scroll_interval = 1000; // one sec (in millis)
chart.series = {
    "all" : {
        "name"   : "Overall Average",
        "active" : true
    },
    "male" : {
        "name"   : "Male",
        "active" : true
    },
    "female" : {
        "name"   : "Female",
        "active" : true
    }
};
chart.ref_series = "all";
chart.fill_left_pts(1, 60.0, 0);

chart.render();

// client's responsibility for d3tsline scrolling is to populate
// chart.next_pts, which is an array of data series 'y' values for the next
// point(s) to be drawn during the next interval.
var start = Math.floor(new Date().getTime()/1000);

// refresh data loop
var refresh_data = window.setInterval( function() {
    var sec = Math.floor(new Date().getTime()/1000) - start;
    var y1 = Math.sin(sec/3) * 50+ 20 ;
    var y2 = Math.cos(sec/3) * 50+ 80 ;

    chart.next_pts = {
        all:   GetRandomNum(10,80),
        male:   GetRandomNum(10,80),
        female: GetRandomNum(10,80)
    };

}, 1000 );

chart.start_scroll(); // begin scrolling

// shut down refresh loops after a few secs (for dev)
var cmd =
    "window.clearInterval(refresh_data);" +
    "chart.stop_scroll();";
// var cancel_refresh = setTimeout(cmd, 120 * 1000);
