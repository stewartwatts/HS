#!/usr/bin/env julia
using DataFrames
using Distributions

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

### TODO
function summarize_log(path="logs/gaussy_log.txt")
end
    
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
            func_msg = []
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
                kurt_vals[cn] = [kurt_vals[cn], best_kurt]
                func_msg = [func_msg, gs[min_g]]
            end
        end
        if log
            all_msg = string([string(cn,":"),
                              string("transforms: ", join(func_msg, " ")),
                              string("kurt vals: [", join(map(string, kurt_vals[cn]), " "), "]"),
                              string("diagnostics: ", diagnositc_msg())],
                             "\n")
            write_log(filename, all_msg)
        end
        # modify df IN-PLACE
        df[cn] = tmp
    end
    return
end
