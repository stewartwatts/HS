#!/usr/bin/env julia
using DataFrames
using Distributions

# upper index that is 1% - 15% of a vector's length
upperindex(x::DataArray{Float64,1}) = int(length(x)/100 * rand()*14 + 1)

# identity
f1(x::DataArray{Float64,1}) = x

# log
f2(x::DataArray{Float64,1}) = log(x)

# exponential
f3(x::DataArray{Float64,1}) = exp(x)

# number indicating missing value assigned to to 1-15% of vector
function f4(x::DataArray{Float64,1})
    y = deepcopy(x)
    for _ in 1:upperindex(y)
        y[int(rand()*length(y))+1] = -999
    end
    return y
end

# NA assigned to 1-15% of vector
function f5(x::DataArray{Float64,1})
    y = deepcopy(x)
    for _ in 1:upperindex(y)
        y[int(rand()*length(y))+1] = NA
    end
    return y
end

# upper tail discontinuous
function f6(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = int(length(y)/100.0 * (1 + 5*rand()))
    uppertail = int(length(y)/100.0 * (100 - int(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:upperindex(y)
        y[int(rand()*length(y)+1)] = upy + yrng*(1+rand())
    end
    return y
end

# lower tail discontinuous
function f7(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = int(length(y)/100.0 * (1 + 5*rand()))
    uppertail = int(length(y)/100.0 * (100 - int(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:upperindex(y)
        y[int(rand()*length(y)+1)] = loy - yrng*(1+rand())
    end
    return y
end

# both tails disconinuous
function f8(x::DataArray{Float64,1})
    y = deepcopy(x)
    lowertail = int(length(y)/100.0 * (1 + 5*rand()))
    uppertail = int(length(y)/100.0 * (100 - int(1 + 5*rand())))
    loy = sort(removeNA(y))[lowertail]
    upy = sort(removeNA(y))[uppertail]
    yrng = upy-loy
    for _ in 1:int(upperindex(y)/2)
        y[int(rand()*length(y)+1)] = upy + yrng*(1+rand())
    end
    for _ in 1:int(upperindex(y)/2)
        y[int(rand()*length(y)+1)] = loy - yrng*(1+rand())
    end
    return y
end

# power up
function f9(x::DataArray{Float64,1})
    y = x .^ (10*rand())
    return sum(isnan(y)) == 0 ? y : x
end

# power down
function f10(x::DataArray{Float64,1})
    y = x .^ (1/(10*rand()))
    return sum(isnan(y)) == 0 ? y : x
end   

# negative power / reciprocal
f11(x::DataArray{Float64,1}) = 1 ./ x

funcs = [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11]

# function with metrics
function score_gauss(df::DataFrame)
    kurts = map(c -> kurtosis(removeNA(df[c])), colnames(df)) 
    skews = map(c -> skewness(removeNA(df[c])), colnames(df)) 
    return (kurts, skews)
end


# create a DataFrame with messy, un-gaussian columns
df = DataFrame(randn(10000,8*length(funcs)));
for i in 1:length(funcs)
    df[i] = funcs[i](df[i])
end
for i in (length(funcs)+1):4*length(funcs)
    fs = sample(1:length(funcs),2)
    df[i] = funcs[fs[1]](funcs[fs[2]](df[i]))
end
for i in (4*length(funcs)+1):8*length(funcs)
    fs = sample(1:length(funcs),3)
    df[i] = funcs[fs[1]](funcs[fs[2]](funcs[fs[3]](df[i])))
end


#   ---- gaussianify ----
# - take log of variable
# - remove mode (ex: -999 being error value) 
# - cut sorted variable  at left tail, right tail, both tails
# - WARN: heavy quantization, too many NAs

g1(x::DataArray{Float64,1}) = log(x)  # log
g2(x::DataArray{Float64,1}) = 1/x     # reciprocal
g3(x::DataArray{Float64,1}) = exp(x)  # exponential
g4(x::DataArray{Float64,1}) = x.^2    # power up
g5(x::DataArray{Float64,1}) = x.^0.5  # power down
function g6(x::DataArray{Float64,1})
    # convert non-NA mode to NA (it may be missing)
    tab = table(x)
    (cnt, xmode) = max([isna(k) ? (NA,-1) : (v,k) for (k,v) in tab])
    if cnt > 1
        x[x .== xmode] = NA
    end
    return x
end
function g7(x::DataArray{Float64,1}, lo_cut::Int64, hi_cut::Int64)
    # chop off vals above / below a set of quantiles
    
end

function gaussy(df::DataArray{Float64,1})
    fixers = [global g1,
              global g2,
              global g3,
              global g4,
              global g5,
              global g6,
              global g7]
end

show_metrics(df)
df = gaussy(df)
show_metrics(df)
