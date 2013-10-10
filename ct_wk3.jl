#!/usr/bin/env julia

# 4.
lamb = [0., 0.5, 1./sqrt(2.), 1.0]
mu = linspace(0,1,101)
perf = zeros(length(mu),length(lamb))
function perf_h(lamb, mu)
    N = 10000
    p = (1.-lamb) * (1.-mu) + lamb * mu
    res = rand(N)
    res[find(res .<= p)] = 0
    res[find(res .> p)] = 1
    return float(sum(res))/N
end
for j in 1:length(lamb), i in 1:length(mu)
    perf[i,j] = perf_h(lamb[j], mu[i])
end
std_by_lamb = map(x -> std(perf[:,x]), [1:4])
println("std deviations by lambda [0, 0.5, 1/sqrt(2), 1]")
println(std_by_lamb)

# 5.
using DataFrames
using Gadfly
import Base.show

type Point
    x0::Float64
    x1::Float64
    x2::Float64
    Point(x1,x2) = new(1.0, x1, x2)
end

type Line
    slope::Float64
    intercept::Float64
end

makepoint() = Point(1-2*rand(), 1-2*rand())
makeline() = line_from_points(makepoint(), makepoint())

function line_from_points(p1,p2)
    slope = (p2.x2 - p1.x2) / (p2.x1 - p1.x1)
    intercept = p1.x2 - slope * p1.x1
    return Line(slope, intercept)
end

function wgt_from_line(l::Line)
    w2 = 0.5
    w1 = -l.slope * w2
    w0 = -l.intercept * w2
    return [w0, w1, w2]
end

function line_from_wgt(w::Array{Float64,1})
    return Line(-w[2]/w[3], -w[1]/w[3])
end
    
type LinReg
    x::Array{Float64,2}
    f::Line
    y::Array{Float64,1}
    w_star
    
    function LinReg(N)
        x = zeros(N,3)
        y = zeros(N)
        f = makeline()
        for i in 1:N
            p = makepoint()
            x[i,:] = [p.x0, p.x1, p.x2]
            y[i] = evaluate(p, f)
        end
        new(x,f,y,nothing)
    end
end

function evaluate(p::Point, l::Line)
    w = wgt_from_line(l)
    return ([p.x0, p.x1, p.x2]' * w)[1] >= 0. ? 1. : -1.
end

function add_points(LinReg, N)
    new_x = zeros(N, 3)
    new_y = zeros(N)
    for i = 1:N
        p = makepoint()
        new_x[i,:] = [p.x0, p.x1, p.x2]
        new_y[i] = evaluate(p, LinReg.f)
    end
    LinReg.x = [LinReg.x; new_x]
    LinReg.y = [LinReg.y; new_y]
    return
end

function solve(lr::LinReg)
    println("solving LinReg ...")
    lr.w_star = pinv(lr.x' * lr.x) * lr.x' * lr.y
    return
end

function LRplot(lr::LinReg)
    df = DataFrame()
    df["x1"] = lr.x[:,2]
    df["x2"] = lr.x[:,3]
    df["y"] = lr.y
    df["line_x"] = linspace(min(lr.x[:,2]), max(lr.x[:,2]), length(lr.y))
    df["act_y"] = df["line_x"] * lr.f.slope + lr.f.intercept
    if typeof(lr.w_star) == Nothing
        solve(lr)
    end
    mod_line = line_from_wgt(lr.w_star)
    df["mod_y"] = df["line_x"] * mod_line.slope + mod_line.intercept
    p = plot(df,
             layer(x="x1",y="x2", color="y", Geom.point),
             layer(x="line_x", y="act_y", Geom.line),
             layer(x="line_x", y="mod_y", Geom.line))
    draw(PNG("lt_plot.png", 10inch, 7inch), p)
end

function show(io::IO, lr::LinReg)
    println(io, "x:")
    show(io, lr.x)
    print(io, "\n\n")
    println(io, "y:")
    show(io, lr.y)
    print(io, "\n\n")
    println(io, "True:")
    show(io, lr.f)                       # Line
    print("\n")
    show(io, wgt_from_line(lr.f))        # wgts
    print(io, "\n\n")
    println(io, "Model:")
    show(io, line_from_wgt(lr.w_star))   # Line
    print("\n")
    show(io, lr.w_star)                  # wgts
    print(io, "\n\n")
end

#########################
#test
lr = LinReg(10);
solve(lr)
lr
LRplot(lr)
#########################

# 6.

# 7.

# 8.

# 9.

# 10.

