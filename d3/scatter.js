/* CSS for the axis class

<style>
  .axis path,
  .axis line {
    fill: none;
    stroke: black;
    shape-rendering: crispEdges;
  }

  .axis text {
    font-family: sans-serif;
    font-size: 11px;
  }	  
</style>

*/




// data
var dataset = [
                [5, 20], [480, 90], [250, 50], [100, 33], [330, 95],
                [410, 12], [475, 44], [25, 67], [85, 21], [220, 88]
              ];

// svg params
var w = 500;
var h = 100;
var padding = 30;

// scales
var xScale = d3.scale.linear()
               .domain([0, d3.max(dataset, function(d) {return d[0];})])
               .range([padding, w-padding*2]);
var yScale = d3.scale.linear()
               .domain([0, d3.max(dataset, function(d) {return d[1];})])
               .range([h-padding, padding]);   //COOL -> inversion of y-scale
/*var rScale = d3.scale.linear()
               .domain([0, d3.max(dataset, function(d) {return d[1];})])
               .range([2,2])
               .clamp(true)*/

// axes
var xAxis = d3.svg.axis()
              .scale(xScale)
              .orient("bottom")
              .ticks(5);
var yAxis = d3.svg.axis()
              .scale(yScale)
              .orient("left")
              .ticks(5);              

// SVG
var svg = d3.select("body")
            .append("svg")
            .attr("width", w)
            .attr("height", h);

svg.selectAll("circle")
   .data(dataset)
   .enter()
   .append("circle")
   .attr("cx", function(d) {return xScale(d[0]);})
   .attr("cy", function(d) {return yScale(d[1]);})
   .attr("r", 2);

/*svg.selectAll("text")
   .data(dataset)
   .enter()
   .append("text")
   .text(function(d) {return d[0] + "," + d[1];})
   .attr("x", function(d) {return xScale(d[0]);})
   .attr("y", function(d) {return yScale(d[1]);})
   .attr("font-family", "sans-serif")
   .attr("font-size", "11px")
   .attr("fill", "red");*/

// create axes
svg.append("g")
   .attr("class", "x axis")
   .attr("transform", "translate(0," + (h-padding) + ")")
   .call(xAxis);
svg.append("g")
   .attr("class", "y axis")
   .attr("transform", "translate(" + padding + ",0)")
   .call(yAxis);

// modify data on click
d3.select("p")
  .on("click", function() {
      
      // random data
      var dataset = [];
      var numDataPoints = 50;
      var xRange = Math.random() * 1000;
      var yRange = Math.random() * 1000;
      for (var i = 0; i < numDataPoints; i++) {
	  var n1 = Math.round(Math.random() * xRange);
	  var n2 = Math.round(Math.random() * yRange);
	  dataset.push([n1, n2]);
      }
      
      var dur = 1000;

      // rescaling
      xScale.domain([0, d3.max(dataset, function(d) {return d[0];})]);
      yScale.domain([0, d3.max(dataset, function(d) {return d[1];})]);
      xAxis.scale(xScale);
      yAxis.scale(yScale);

      svg.selectAll("circle")
         .data(dataset)
         .transition()
         .duration(dur)
         .attr("cx", function(d) {return xScale(d[0]);})
         .attr("cy", function(d) {return yScale(d[1]);})
         .attr("r", 2);

      svg.select(".x.axis")
         .transition()
         .duration(dur)
         .call(xAxis);
      svg.select(".y.axis")
         .transition()
         .duration(dur)
         .call(yAxis);
});
