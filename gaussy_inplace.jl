#!/usr/bin/env julia
using DataFrames
using Distributions

# upper index that is 1% - 15% of a vector's length
upperindex(x::DataArray{Float64,1}) = int(length(x)/100 * rand()*14 + 1)

# identity
function f1!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = x[i]
    end
    return
end

# log
function f2!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = log(x[i])
    end
    return
end

# exponential
function f3!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = exp(x[i])
    end
    return
end
    
# number indicating missing value assigned to to 1-15% of vector
function f4!(x::DataArray{Float64,1})
    n = length(x)
    for _ in 1:upperindex(x)
        x[int(rand()*n)+1] = -999
    end
    return
end

# NA assigned to 1-15% of vector
function f5!(x::DataArray{Float64,1})
    n = length(x)
    for _ in 1:upperindex(x)
        x[int(rand()*n)+1] = NA
    end
    return
end

# upper tail discontinuous
function f6!(x::DataArray{Float64,1})
    n = length(x)
    lowertail = int(n * (1 + 5*rand()))
    uppertail = int(n * (100 - int(1 + 5*rand())))
    lox = sort(x)[lowertail]
    upx = sort(x)[uppertail]
    xrng = upx-lox
    for _ in 1:upperindex(x)
        x[int(rand()*n+1)] = upx + xrng*(1+rand())
    end
    return
end

# lower tail discontinuous
function f7!(x::DataArray{Float64,1})
    n = length(x)
    lowertail = int(n * (1 + 5*rand()))
    uppertail = int(n * (100 - int(1 + 5*rand())))
    lox = sort(x)[lowertail]
    upx = sort(x)[uppertail]
    xrng = upx-lox
    for _ in 1:upperindex(x)
        x[int(rand()*n+1)] = lox - xrng*(1+rand())
    end
    return
end

# both tails discontinuous
function f8!(x::DataArray{Float64,1})
    n = length(x)
    lowertail = int(n * (1 + 5*rand()))
    uppertail = int(n * (100 - int(1 + 5*rand())))
    lox = sort(x)[lowertail]
    upx = sort(x)[uppertail]
    xrng = upx-lox
    for _ in 1:int(upperindex(x)/2)
        x[int(rand()*length(x)+1)] = upx + xrng*(1+rand())
    end
    for _ in 1:int(upperindex(x)/2)
        x[int(rand()*length(x)+1)] = lox - xrng*(1+rand())
    end
    return
end

# power up
function f9!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = x[i] ^ (10*rand())
    end
    return
end

# power down
function f10!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = x[i] ^ (1/(10*rand()))
    end
    return
end

# negative power / reciprocal
function f11!(x::DataArray{Float64,1})
    for i in 1:length(x)
        x[i] = x[i] ^ (-1.0)
    end
    return
end

funcs = [f1!, f2!, f3!, f4!, f5!, f6!, f7!, f8!, f9!, f10!]

# function with metrics
function score_gauss(df::DataFrame)
    kurts = map(c -> kurtosis(removeNA(df[c])), colnames(df)) 
    skews = map(c -> skewness(removeNA(df[c])), colnames(df)) 
    return (kurts, skews)
end


# create a DataFrame with messy, un-gaussian columns
df = DataFrame(randn(10000,8*length(funcs)));
n = length(funcs)
for j in 1:n
    funcs[j](df[string("x",j)])
end
for j in (n+1):4*n
    fs = sample(1:n,2)
    funcs[fs[1]](df[string("x",j)])
    funcs[fs[2]](df[string("x",j)])
end
for j in (4*n+1):8*n
    fs = sample(1:n,3)
    funcs[fs[1]](df[string("x",j)])
    funcs[fs[2]](df[string("x",j)])
    funcs[fs[3]](df[string("x",j)])
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
