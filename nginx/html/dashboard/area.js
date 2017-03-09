/**
 * Created by tietang on 2016/9/23.
 */

function newArea(options) {

    var limit = 100 * 1,
        duration = 1000,
        now = new Date(Date.now() - duration)

    var width = options.width | 600,
        height = options.height | 300;

    var group = {
        value: 0,
        color: 'green',
        data: d3.range(limit).map(function () {
            return 0
        })
    }

    var x = d3.scaleTime()
        .domain([now - (limit - 2), now - duration])
        .range([0, width])

    var y = d3.scaleLinear()
        .domain([0, 100])
        .range([height, 0])

    var area = d3.area()
    //
        .x(function (d, i) {
            return x(now - (limit - 1 - i) * duration)
        })
        .y0(height)
        .y1(function (d) {
            return y(d);
        })
        .curve(d3.curveBasis);

    var el = document.getElementById(options.id | "graph")
    var svg = d3.select("div[id="+options.id+"]").append('svg')
        .attr('class', 'chart')
        .attr('width', width)
        .attr('height', height + 50)

    //        var axis = svg.append('g')
    //            .attr('class', 'x axis')
    //            .attr('transform', 'translate(0,' + height + ')')
    //            .call(x.axis = d3.svg.axis().scale(x).orient('bottom'))

    var paths = svg.append('g')


    group.path = paths.append("path")
        .datum(group.data)
        .attr("class", "area")
        .attr("d", area);

    function tick() {
        var url = "/_admin/qps.json";
        $.get(url, function (rdata) {


            var ms = rdata.date;
            var close = rdata.close;

            $("#text").html(close * 100 + " q/s");

            now = new Date()
            now.setTime(ms)


            // Add new values
            group.data.push(close * 10);
//                    group.data.push(Math.random() * 100);
            group.path.attr('d', area);

            // Shift domain
            x.domain([now - (limit - 2) * duration, now - duration])

            // Slide x-axis left
//            axis.transition()
//                .duration(500)
//                .ease('linear')
//                .call(x.axis)

            // Slide paths left
            paths.attr('transform', null)
                .transition()
                .duration(500)
                //                    .ease('linear')
                .attr('transform', 'translate(' + x(now - (limit - 1) * duration) + ')')


            // .each('end', tick)

            // Remove oldest data point from each group
            group.data.shift()
//            console.log(group.data)
        });

    }

    setInterval(tick, 1000);
}