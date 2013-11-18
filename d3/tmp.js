// nice bar plots
var dataset = [100, 200, 300, 400, 500];

var w = 500;
var h = 100;
var barPadding = 1;

var xScale = d3.scale.linear()
               .domain([0, d3.max(dataset, function(d) {return d[0];})])
               .range([0, w]);
var yScale = d3.scale.linear()
               .domain([0, d3.max(dataset, function(d) {return d[1];})])
               .range([0, h]);
