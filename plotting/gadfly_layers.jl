using DataFrames
using Gadfly

df = DataFrame()
# random points on [-1, 1] x [-1, 1]
df["x1"] = 1. - 2. * rand(100)
df["x2"] = 1. - 2. * rand(100)
# x-axis values for lines I want to draw (on same scale as x1 / x2)
df["line_x"] = linspace(min(df["x1"]), max(df["x1"]), size(df,1))
df["line_y"] = -.2 + 0.8 * df["line_x"]

# REFERENCE:
#   https://groups.google.com/forum/#!topic/julia-users/D7MGL1v9YMM
#   Using Daniel Jones's first entry

p = plot(df,
         Layer(x="x1",y="x2", Geom.point),
         Layer(x="line_x", y="line_y", Geom.line))
draw(PNG("lt_plot.png", 7inch, 7inch), p)

# Fails to set "p":
# ERROR: no method layer(Array{Any,1},DataType)

