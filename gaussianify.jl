#!/usr/bin/env julia
using DataFrames
using Distributions

# upper index that is 1% - 15% of a vector's length
upperindex(x) = int(length(x)/100 * rand()*14 + 1)

# identity
f1(x) = x

# exponential
f2(x) = exp(x)

# number indicating missing value assigned to to 1-15% of vector
function f3(x)
    for _ in 1:upperindex(x)
        x[int(rand()*length(x))+1] = -999
    end
    x
end

# NA assigned to 1-15% of vector
function f4(x)
    for _ in 1:upperindex(x)
        x[int(rand()*length(x))+1] = NA
    end
    x
end

# upper tail discontinuous
function f5(x)
    lowertail = int(length(x) * (1 + 5*rand()))
    uppertail = int(length(x) * (100 - int(1 + 5*rand())))
    lox = sort(x)[lowertail]
    upx = sort(x)[uppertail]
    xrng = upx-lox
    for _ in 1:upperindex(x)
        x[int(rand()*length(x)+1)] = upx + xrng*(1+rand())
    end
    x
end

# lower tail discontinuous
function f6(x)
    -f5(x)
end

# both tails disconinuous
function f7(x)
    lowertail = int(length(x) * (1 + 5*rand()))
    uppertail = int(length(x) * (100 - int(1 + 5*rand())))
    lox = sort(x)[lowertail]
    upx = sort(x)[uppertail]
    xrng = upx-lox
    for _ in 1:int(upperindex(x)/2)
        x[int(rand()*length(x)+1)] = upx + xrng*(1+rand())
    end
    for _ in 1:int(upperindex(x)/2)
        x[int(rand()*length(x)+1)] = lox - xrng*(1+rand())
    end
    x
end

funcs = [f1, f2, f3, f4, f5, f6, f7]
    
# create a DataFrame with well-behaved and messy columns
df = DataFrame()
for i in 1:7
    df[string("x",i)] = funcs[i](randn(10000))
end
for i in 8:24
    fs = sample(1:length(funcs),2)
    df[string("x",i)] = funcs[fs[1]](funcs[fs[2]](randn(10000)))
end
for i in 25:50
    fs = sample(1:length(funcs),3)
    df[string("x",i)] = funcs[fs[1]](funcs[fs[2]](funcs[fs[3]](randn(10000))))
end


# gaussianify
# - take log of variable
# - remove mode (ex: -999 being error value) 
# - cut sorted variable  at left tail, right tail, both tails
# - WARN: heavy quantization, too many NAs

