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

function f8(x)
    x ** 10*rand()
end

function f9(x)
    x ** 1/(10*rand())
end  

funcs = [f1, f2, f3, f4, f5, f6, f7, f8, f9]

# function with metrics
function score_gauss(df)
    kurts = map(c -> kurtosis(df[c]), colnames(df)) 
    skews = map(c -> skew(df[c]), colnames(df)) 
    return (kurts, skews)
end


# create a DataFrame with well-behaved and messy columns
df = DataFrame(randn(10000,8*length(funcs)));
for i in 1:length(funcs)
    #df[string("x",i)] = funcs[i](df[string("x",i)])
    plot(df[string("x",i)])
end
for i in (length(funcs)+1):4*length(funcs)
    fs = sample(1:length(funcs),2)
    df[string("x",i)] = funcs[fs[1]](funcs[fs[2]](df[string("x",i)]))
end
for i in (4*length(funcs)+1):8*length(funcs)
    fs = sample(1:length(funcs),3)
    df[string("x",i)] = funcs[fs[1]](funcs[fs[2]](funcs[fs[3]](df[string("x",i)])))
end

function show_metrics(df::DataFrame)
    ####
end

#   ---- gaussianify ----
# - take log of variable
# - remove mode (ex: -999 being error value) 
# - cut sorted variable  at left tail, right tail, both tails
# - WARN: heavy quantization, too many NAs
function gaussy()
    ####
end

show_metrics(df)
df = gaussy(df)
show_metrics(df)

function double!(x)
    x = 2 * x
    return
end

function double(x)
    x = 2*x
end
