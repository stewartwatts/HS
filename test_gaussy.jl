#!/usr/bin/env julia
using DataFrames
using Distributions

include("gaussy.jl")

# upper index that is 1% - 12% of a vector's non-NA length
upperindex(x::DataArray{Float64,1}) = ifloor(length(removeNA(x))/100 * rand()*11 + 1)

# identity
f1(x::DataArray{Float64,1}) = x

# make all-positive (probably)
f2(x::DataArray{Float64,1}) = 20. + x * 3.

# log
f3(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? log(x) : x

# exponential
f4(x::DataArray{Float64,1}) = exp(x)

# number indicating missing value assigned to to 1-12% of vector
function f5(x::DataArray{Float64,1})
    y = deepcopy(x)
    for _ in 1:upperindex(y)
        y[ifloor(rand()*length(y))+1] = -999
    end
    return y
end

# NA assigned to 1-12% of vector
function f6(x::DataArray{Float64,1})
    y = deepcopy(x)
    for _ in 1:upperindex(y)
        y[ifloor(rand()*length(y))+1] = NA
    end
    return y
end

# upper tail discontinuous
function f7(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = ifloor(length(removeNA(y))/100.0 * ifloor(1 + 5*rand()))
    uppertail = ifloor(length(removeNA(y))/100.0 * (100 - ifloor(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:upperindex(y)
        y[ifloor(rand()*length(y)+1)] = upy + yrng*(1+rand())
    end
    return y
end

# lower tail discontinuous
function f8(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = ifloor(length(removeNA(y))/100.0 * ifloor(1 + 5*rand()))
    uppertail = ifloor(length(removeNA(y))/100.0 * (100 - ifloor(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:upperindex(y)
        y[ifloor(rand()*length(y)+1)] = loy - yrng*(1+rand())
    end
    return y
end

# both tails discontinuous
function f9(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = ifloor(length(removeNA(y))/100.0 * ifloor(1 + 5*rand()))
    uppertail = ifloor(length(removeNA(y))/100.0 * (100 - ifloor(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:ifloor(upperindex(y)/2)
        y[ifloor(rand()*length(y)+1)] = upy + yrng*(1+rand())
    end
    for _ in 1:ifloor(upperindex(y)/2)
        y[ifloor(rand()*length(y)+1)] = loy - yrng*(1+rand())
    end
    return y
end

# power up
f10(x::DataArray{Float64,1}) = min(removeNA(x)) >= 0.0 ? x .^ (10*rand()) : x
    
# power down
f11(x::DataArray{Float64,1}) = min(removeNA(x)) >= 0.0 ? x .^ (1.0/(10*rand())) : x

# negative power / reciprocal
f12(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? 1 ./ x : x

funcs = [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12]

##  -- implement test data set --  ##
# create a DataFrame with messy, un-gaussian columns
func_hist = Dict{Int64,Array{Function,1}}()
df = DataFrame(randn(10000,8*length(funcs)));
for i in 1:length(funcs)
    df[i] = funcs[i](df[i])
    func_hist[i] = [funcs[i]]
end
for i in (length(funcs)+1):4*length(funcs)
    fs = sample(1:length(funcs),2)
    df[i] = funcs[fs[1]](funcs[fs[2]](df[i]))
    func_hist[i] = [funcs[fs[1]], funcs[fs[2]]]
end
for i in (4*length(funcs)+1):8*length(funcs)
    fs = sample(1:length(funcs),3)
    df[i] = funcs[fs[1]](funcs[fs[2]](funcs[fs[3]](df[i])))
    func_hist[i] = [funcs[fs[1]], funcs[fs[2]], funcs[fs[3]]]
end

old_df = deepcopy(df)
gaussy!(df; log=true, plot=true)
