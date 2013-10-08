#!/usr/bin/env julia
using DataFrames
using Distributions
using Gadfly

#   ---- gaussianify ----
# - transformations of variable, mode removal (ex: -999 being error value)
# - cut sorted variable at left tail, right tail, both tails
# - WARN: heavy quantization, too many NAs

# function with metrics
function score_gauss(df::DataFrame)
    kurts = map(c -> kurtosis(removeNA(df[c])), colnames(df)) 
    skews = map(c -> skewness(removeNA(df[c])), colnames(df)) 
    return (kurts, skews)
end

function plot_quantiles(df::DataFrame, filename::ASCIIString)
    p = plot(df, x="quantiles", y="kurtosis", color="when", Geom.line)
    draw(PNG(filename, 10inch, 6inch), p)
end

function plot_metrics_from_log(kurts, filename="logs/gaussy_log.txt")
    using Gadfly
    # parse log file
    # TODO
    
    # plot starting / final quantiles (10% 20% ...) of sorted kurtoses
    # TODO
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
g1(x::DataArray{Float64,1}) = min(removeNA(x)) >= 0.0 ? log(x) : x

# reciprocal
g2(x::DataArray{Float64,1}) = min(removeNA(x)) >= 0.0 ? 1.0 / x : x

# exponential
g3(x::DataArray{Float64,1}) = exp(x)

# power up
g4(x::DataArray{Float64,1}) = x.^2

# power down
g5(x::DataArray{Float64,1}) = min(removeNA(x)) >= 0.0 ? x.^0.5 : x

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
    while qnt < 0.05 && (abs(kurts[qnt]) - abs(kurts[qnt+0.01])) > 1.0
        qnt += 0.01
    end
    cut_val = quantile(x_na, qnt)
    y = deepcopy(x)
    y[find(y .< cut_val)] = NA
    return y
end
    
function gaussy!(df::DataFrame; log=false, filename="logs/gaussy_log.txt", plot=false)
    num_cols = filter(c -> eltype(df[c]) <: Number, colnames(df))
    # gaussifiers => log messages
    gs = {g0 => "none;",
          g1 => "log(x);",
          g2 => "1/x;",
          g3 => "exp(x);",
          g4 => "x.^2;",
          g5 => "x.^0.5",
          g6 => "mode->NA;",
          g7 => "upp_tail->NA;",
          g8 => "low_tail->NA;"}

    # setup logging
    if log
        init_log(filename)
        counts = {g[1] => 0 for g in gs}
        kurt_vals = {cn => [kurtosis(removeNA(df[cn]))] for cn in colnames(df)}
    end

    # setup plotting
    if plot
        quantiles = linspace(0,1,21)
        # datastructures to contain kurtosis data we will later visualize
        sort_kurts = sort([kurtosis(removeNA(df[cn])) for cn in num_cols])
        before_qtls = [quantile(sort_kurts, q) for q in quantiles]    
    end

    # loop over cols, greedily replacing as abs(kurt) declines
    for cn in filter(c -> eltype(df[c]) <: Number, colnames(df))
        if log
            func_msg = []
        end
        tmp = eltype(df[cn]) <: FloatingPoint ? deepcopy(df[cn]) : 1.0 * deepcopy(df[cn])
        kurts = {g[1] => kurtosis(removeNA(g[1](tmp))) for g in gs}
        best_kurt = min(map(abs, [k[2] for k in kurts]))
        min_g = filter(k -> abs(k[2]) == best_kurt, [k for k in kurts])[1][1]
        while abs(kurts[min_g]) > 1.0 && best_kurt <= (abs(kurts[g0]) - 1.0)
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

        # log as you loop through df
        if log
            all_msg = string([string(cn, ":transforms: ", join(func_msg, " ")),
                              string(cn, ":kurt_vals: [", join(map(string, kurt_vals[cn]), " "), "]"),
                              string(cn, ":diagnostics: ", diagnostic_msg(tmp))],
                             "\n")
            #DEBUG
            println(all_msg)
            #/DEBUG
            open(filename, "a") do f
                write(f, all_msg)
            end
        end
                
        # modify in-place
        df[cn] = tmp
    end

    # do plot difference in kurtosis before / after
    if plot
        sort_kurts = sort([kurtosis(removeNA(df[cn])) for cn in num_cols])
        after_qtls = [quantile(sort_kurts, q) for q in quantiles]

        # create DataFrame for Gadfly plot
        plot_df = DataFrame()
        plot_df["quantiles"] = [quantiles; quantiles; quantiles]
        plot_df["when"]      = [rep("before", 21); rep("after",21); rep("ones", 21)]
        plot_df["kurtosis"]  = [before_qtls; after_qtls; rep(1.0,21)]
        plot_quantiles(plot_df, "logs/gaussy_kurt_plot.png")
    end
       
    return df
end
