// nice bar plots
var dataset = [ 5, 10, 13, 19, 21, 25, 22, 18, 15, 13,
                11, 12, 15, 20, 18, 17, 16, 18, 23, 25 ];

/*var N = dataset.length;
var dataset = []
for (var i = 0; i < N; i++) {
    dataset.push(Math.round(Math.random() * 100));
}*/

var w = 600; 
var h = 250;
var barPadding = 1;

var xScale = d3.scale.ordinal()
               .domain(d3.range(dataset.length))
               .rangeRoundBands([0, w], 0.05)
var yScale = d3.scale.linear()
               .domain([0, d3.max(dataset)])
               .range([10, h])

var svg = d3.select("body")
            .append("svg")
            .attr("width", w)
            .attr("height", h);

svg.selectAll("rect")
   .data(dataset)
   .enter()
   .append("rect")
   .attr("x", function(d, i) {return xScale(i);})
   .attr("y", function(d) {return h - yScale(d);})
   .attr("width", xScale.rangeBand())
   .attr("height", function(d) {return yScale(d);})
   .attr("fill", function(d) {return "rgb(0,0,"+d*10+")";});

svg.selectAll("text")
   .data(dataset)
   .enter()
   .append("text")
   .text(function(d) {return d;})
   .attr("x", function(d,i) {return xScale(i)+xScale.rangeBand()/2;})
   .attr("y", function(d) {return h - yScale(d) + 14;})
   .attr("font-family", "sans-serif")
   .attr("font-size", "11px")
   .attr("fill", "white")
   .attr("text-anchor", "middle");

d3.select("p")
    .on("click", function() {
        
	// new values
	dataset = [11, 12, 15, 20, 18, 17, 16, 18, 23, 25,
                    5, 10, 13, 19, 21, 25, 22, 18, 15, 13];
	
	// update all rects
	svg.selectAll("rect")
	   .data(dataset)
           .transition()
           .attr("y", function(d) {return h - yScale(d);})
	   .attr("height", function(d) {return yScale(d);})
	   .attr("fill", function(d) {return "rgb(0,0,"+d*10+")";});

	// update text
	svg.selectAll("text")
           .data(dataset)
           .text(function(d) {return d;})
           .attr("x", function(d, i) {return xScale(i) + xScale.rangeBand()/2;})
           .attr("y", function(d) {return h - yScale(d) + 14;})
        
    });
