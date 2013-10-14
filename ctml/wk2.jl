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

## SETUP for 5. - 7.
using DataFrames
using Gadfly
using Distributions
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

type PLA
    x::Array{Float64,2}
    f::Line
    y::Array{Float64,1}
    w_star::Array
    iters::Int64
    function PLA(lr::LinReg)
        if typeof(lr::LinReg) == Nothing
            solve(lr)
        end
        new(lr.x, lr.f, lr.y, lr.w_star, 0)
    end
end

function update_w(pla::PLA, row_index::Int)
    pla.w_star = pla.w_star - pla.y[row_index] * pla.x[row_index,:]'
    pla.iters = pla.iters + 1
    return
end

function solve(pla::PLA)
    while sum([evaluate(pla.x[i,:], pla.f) for i in 1:size(pla.x)[1]] .== pla.y) < length(pla.y)
        for i in 1:length(pla.y)
            if evaluate(pla.x[i,:], pla.f) != pla.y[i] 
                break
            end
        end
        update_w(pla)
    end
end

function evaluate(p::Point, l::Line)
    w = wgt_from_line(l)
    return ([p.x0, p.x1, p.x2]' * w)[1] >= 0. ? 1. : -1.
end

function evaluate(p::Array{Float64,2}, l::Line)
    w = wgt_from_line(l)
    return (p * w)[1] >= 0. ? 1. : -1.
end

function evaluate(p::Array{Float64,2}, w::Array{Float64,1})
    return (p * w)[1] >= 0. ? 1. : -1.
end

function add_points(lr::LinReg, N)
    new_x = zeros(N, 3)
    new_y = zeros(N)
    for i = 1:N
        p = makepoint()
        new_x[i,:] = [p.x0, p.x1, p.x2]
        new_y[i] = evaluate(p, lr.f)
    end
    lr.x = [lr.x; new_x]
    lr.y = [lr.y; new_y]
    return
end

function solve(lr::LinReg)
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
    if typeof(lr.w_star) == Nothing
        solve(lr)
    end
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

function show(io::IO, pla::PLA)
    println(io, "True:")
    show(io, pla.f)                       # Line
    print("\n")
    show(io, wgt_from_line(pla.f))        # wgts
    print(io, "\n\n")
    println(io, "Model:")
    show(io, line_from_wgt(pla.w_star))   # Line
    print("\n")
    show(io, pla.w_star)                  # wgts
    print(io, "\n\n")
    println(io, "Iters:")
    show(io, pla.iters)
    print("\n\n")
    println("Num wrong:")
    show(io, length(pla.y) - sum([evaluate(pla.x[i,:], pla.f) for i in 1:size(pla.x)[1]] .== pla.y))
        
end


#########################
#test
lr = LinReg(10);
solve(lr)
pla = PLA(lr);
pla
solve(pla)
pla
[evaluate(pla.x[i,:], pla.f) for i in 1:size(pla.x)[1]] .== pla.y
#########################

# 5.
runs = 1000;
wrongs = zeros(runs);
for i in 1:runs
    lr = LinReg(100)
    solve(lr)
    for j in 1:size(lr.x)[1]
        wrongs[i] += evaluate(lr.x[j,:], lr.f) == evaluate(lr.x[j,:], lr.w_star) ? 0. : 1.
    end
end
println(mean(wrongs/100))

# 6.
runs = 1000;
wrongs = zeros(runs);
for i in 1:runs
    N = 100
    lr = LinReg(N)
    solve(lr)
    add_points(lr, 1000)
    for j in (N+1):size(lr.x)[1]
        #wrongs[i] += evaluate(lr.x[j,:], lr.f) == evaluate(lr.x[j,:], lr.w_star) ? 0. : 1.
        wrongs[i] += lr.y[j] == evaluate(lr.x[j,:], lr.w_star) ? 0. : 1.
    end
end
println(wrongs)
println(mean(wrongs/1000))

# 7.
runs = 1000
n_iter = rand(runs)
for k = 1:runs
    lr = LinReg(10);
    solve(lr)
    pla = PLA(lr);
    solve(pla)
    n_iter[k] = pla.iters
end
       
    
# 8.
f(x1::Float64,x2::Float64) = (x1 ^ 2. + x2 ^ 2. - 0.6) >= 0 ? 1. : -1.

function experiment8()
    N = 1000
    lr = LinReg(N)
    # override the standard lr.y generation
    for i = 1:N
        lr.y[i] = f(lr.x[i,2:3]...)
    end
    inds = sample([1:N], int(N*.1), replace=false)
    for i in inds
        if lr.y[i] == 1.
            lr.y[i] = -1.
        elseif lr.y[i] == -1.
            lr.y[i] = 1.
        else
            throw(DomainError())
        end
    end
    solve(lr)

    # get in-sample classification error
    return sum([evaluate(lr.x[i,:], lr.w_star) for i in 1:length(lr.y)] .!= lr.y) / float(N)
end

function plotLR(lr::LinReg)
    df = DataFrame()
    df["x1"] = lr.x[:,2]
    df["x2"] = lr.x[:,3]
    df["y"]  = lr.y
    p = plot(df, x="x1", y="x2", color="y", Geom.point)
    draw(SVG("myplot.svg", 10inch, 10inch), p)
end
    
runs = 1000
class_error = rand(runs)
for j in 1:runs
    class_error[j] = experiment8()
end
print("average classification error: ")
print(mean(class_error))
    
# 9.
function experiment9()
    N = 1000
    lr = LinReg(N)
    # override the standard lr.y generation
    for i = 1:N
        lr.y[i] = f(lr.x[i,2:3]...)
    end
    inds = sample([1:N], int(N*.1), replace=false)
    for i in inds
        if lr.y[i] == 1.
            lr.y[i] = -1.
        elseif lr.y[i] == -1.
            lr.y[i] = 1.
        else
            throw(DomainError())
        end
    end

    # transform lr.x
    lr.x = [lr.x lr.x[:,2].*lr.x[:,3] lr.x[:,2].^2 lr.x[:,3].^2];
    
    solve(lr)

    # get in-sample classification error
    #return sum([evaluate(lr.x[i,:], lr.w_star) for i in 1:length(lr.y)] .!= lr.y) / float(N)
    return lr
end

lr = experiment9()
println(lr.w_star)

    
# 10.
function experiment10()
    N = 1000
    lr = LinReg(N)
    # override the standard lr.y generation
    for i = 1:N
        lr.y[i] = f(lr.x[i,2:3]...)
    end
    inds = sample([1:N], int(N*.1), replace=false)
    for i in inds
        if lr.y[i] == 1.
            lr.y[i] = -1.
        elseif lr.y[i] == -1.
            lr.y[i] = 1.
        else
            throw(DomainError())
        end
    end
    
    # transform lr.x
    lr.x = [lr.x lr.x[:,2].*lr.x[:,3] lr.x[:,2].^2 lr.x[:,3].^2];

    solve(lr)
    w_star = deepcopy(lr.w_star)
    
    # generate a new lr.x and re-transform
    lr = LinReg(N)
    for i = 1:N
        lr.y[i] = f(lr.x[i,2:3]...)
    end
    inds = sample([1:N], int(N*.1), replace=false)
    for i in inds
        if lr.y[i] == 1.
            lr.y[i] = -1.
        elseif lr.y[i] == -1.
            lr.y[i] = 1.
        else
            throw(DomainError())
        end
    end
    lr.x = [lr.x lr.x[:,2].*lr.x[:,3] lr.x[:,2].^2 lr.x[:,3].^2];
    lr.w_star = w_star
    
    # get in-sample classification error
    return sum([evaluate(lr.x[i,:], lr.w_star) for i in 1:length(lr.y)] .!= lr.y) / float(N)
end
    
runs = 1000;
class_error = rand(runs);
for j in 1:runs
    class_error[j] = experiment10()
end
println("average classification error: ")
println(mean(class_error))
