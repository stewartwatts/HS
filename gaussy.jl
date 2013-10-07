#!/usr/bin/env julia
using DataFrames
using Distributions

# upper index that is 1% - 12% of a vector's non-NA length
upperindex(x::DataArray{Float64,1}) = ifloor(length(removeNA(x))/100 * rand()*11 + 1)

# identity
f1(x::DataArray{Float64,1}) = x

# make all-positive (probably)
f2(x::DataArray{Float64,1}) = 20 + x * 3

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
f10(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? x .^ (10*rand()) : x
    
# power down
f11(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? x .^ (1.0/(10*rand())) : x

# negative power / reciprocal
f12(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? 1 ./ x : x

funcs = [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12]

##  -- implement test data set --  ##
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
# - take transformations of variable
# - remove mode (ex: -999 being error value) 
# - cut sorted variable at left tail, right tail, both tails
# - WARN: heavy quantization, too many NAs

# function with metrics
function score_gauss(df::DataFrame)
    kurts = map(c -> kurtosis(removeNA(df[c])), colnames(df)) 
    skews = map(c -> skewness(removeNA(df[c])), colnames(df)) 
    return (kurts, skews)
end

function init_log(filename)
    if !isdir("logs")
        run(`mkdir logs/`)
    end
    if isfile(joinpath("logs", filename))
        # kill file so it can be overwritten
        run(`rm $(joinpath("logs",filename))`)
    end
end
    
function write_log(filename, msg):
    open(filename, "a") do f
        write(f, msg)
    end
end

### TODO TODO
function summarize_log(path="logs/gaussy_log.txt")
end
### TODO TODO
    
function diagnostic_msg(x::DataArray{Float64,1})
    msg = []
    if float(sum(isna(x)))/length(x) > 0.25
        msg = [msg, "Over 25% NA;"]
    elseif float(sum(isna(x)))/length(x) > 0.10
        msg = [msg, "Over 10% NA;"]
    end
    tab = table(x)
    if length(tab) < 0.10 * length(x)
        msg = [msg, "Heavy quantization;"]
    end
    return join(msg, " ")
end


# identity
g0(x::DataArray{Float64,1}) = x

# log
g1(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? log(x) : x

# reciprocal
g2(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? 1.0 / x : x

# exponential
g3(x::DataArray{Float64,1}) = exp(x)

# power up
g4(x::DataArray{Float64,1}) = x.^2

# power down
g5(x::DataArray{Float64,1}) = min(removeNA(x)) > 0.0 ? x.^0.5 : x

# mode removal
function g6(x::DataArray{Float64,1})
    y = deepcopy(x)
    # convert non-NA mode to NA (it may be missing)
    tab = table(y)
    (cnt, ymode) = max([isna(k) ? (NA,-1) : (v,k) for (k,v) in tab])
    if cnt > 1
        y[y .== ymode] = NA
    end
    return y
end

# chop values above certain quantile
function g7(x::DataArray{Float64,1})
    x_na = removeNA(x)
    kurts = {c => kurtosis(x_na[find(x_na .<= quantile(x_na, c))]) for c in [1.0 0.99 0.98 0.97 0.96 0.95]}
    qnt = 1.0
    while qnt > 0.95 && abs(kurts[qnt]) - abs(kurts[qnt-0.01]) > 1.0
        qnt -= 0.01
    end
    cut_val = quantile(x_na, qnt)
    y = deepcopy(x)
    y[find(y .> cut_val)] = NA
    return y
end

# chop values below certain quantile
function g8(x::DataArray{Float64,1})
    x_na = removeNA(x)
    kurts = {c => kurtosis(x_na[find(x_na .>= quantile(x_na, c))]) for c in [0.0 0.01 0.02 0.03 0.04 0.05]}
    qnt = 0.0
    while qnt < 0.05 && abs(kurts[qnt]) - abs(kurts[qnt+0.01]) > 1.0
        qnt += 0.01
    end
    cut_val = quantile(x_na, qnt)
    y = deepcopy(x)
    y[find(y .< cut_val)] = NA
    return y
end

    
function gaussy!(df::DataArray{Float64,1}, log=false, filename="logs/gaussy_log.txt")
    # gaussifiers => log messages
    gs = [global g0 => "none;",
          global g1 => "log(x);",
          global g2 => "1/x;",
          global g3 => "exp(x);",
          global g4 => "x.^2;",
          global g5 => "x.^0.5",
          global g6 => "mode->NA;",
          global g7 => "upp_tail->NA;",
          global g8 => "low_tail->NA;"}
    if log
        init_log()
        counts = {g: 0 for g in gs}
        kurt_vals = {cn: [kurtosis(removeNA(df[cn]))] for cn in colnames(df)}
    end
    # loop over cols, greedily replacing as abs(kurt) declines
    for cn in colnames(df)
        if log
            msg = []
        end
        tmp = deepcopy(df[cn])
        kurts = {g[1] => kurtosis(removeNA(g[1](tmp))) for g in gs}
        best_kurt = min(map(abs, [k[2] for k in kurts]))
        while abs(kurts[g0]) > 1.0 && best_kurt <= abs(kurts[g0]) - 1.0
            min_g = filter(k -> abs(k[2]) == best_kurt, [k for k in kurts])[1][1]
            tmp = min_g(tmp)
            kurts = {g[1] => kurtosis(removeNA(g[1](tmp))) for g in gs}
            best_kurt = min(map(abs, [k[2] for k in kurts]))
            if log
                counts[min_g] += 1
                kurt_vals = [kurt_val, best_kurt]
                msg = [msg, gs[min_g]]
            end
        end
        if log
            all_msg = string(cn, ":\ntransforms", join(msg, " "), "\nkurt vals:", join(map(string, kurt_vals[cn]), " "), "\ndiagnostics: ", diagnositc_msg(), "\n\n")
            write_log(filename, all_msg)
        end
        # modify df IN-PLACE
        df[cn] = tmp
    end
    return
end

show_metrics(df)
df = gaussy(df)
show_metrics(df)



gs = {g0 => "none;",
           g1 => "log(x);",
           g2 => "1/x;",
           g3 => "exp(x);",
           g4 => "x.^2;",
           g5 => "x.^0.5",
           g6 => "mode->NA;",
           g7 => "upp_tail->NA;",
           g8 => "low_tail->NA;"}
