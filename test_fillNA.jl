using DataFrames
using RDatasets
using GLM

include("fillNA.jl")

function addNAs!(df::DataFrame, exclude_colnames=[], NAratio::FloatingPoint=.15)
# insert NAs to feature vectors (not into Fertility, the response variable)
    cols = filter(c -> !(c in ["" exclude_colnames]), colnames(df))
    (m,n) = size(swiss)
    for col in cols
        df[sample(1:m, int(NAratio*m), replace=false), col] = NA
    end
    return
end

function testfillNA(df::DataFrame, gt_df::DataFrame=nothing, exclude_colnames=[])
    # test performance of optimistic NA-filling vs colmean filling
    df_cp = deepcopy(df)                                    # has NA
    df = optNAfill(df, exclude_colnames=exclude_colnames)   # NA-filled
    # optionally:: gt_df has ground-truth values
    cols = filter(c -> !(c in ["" exclude_colnames]), colnames(df))
    
    for col in cols
        na_inds = find(isna(df_cp[col]))
        println(col)
        println("NA-removed colmean:  ", mean(removeNA(df_cp[col])))
        println("pred vals mean:      ", mean(df[na_inds, col]))
        println("NA-removed colstd:   ", std(removeNA(df_cp[col])))
        println("pred vals std:       ", std(df[na_inds, col]))
        if typeof(gt_df) != Nothing
            println("GT colmean-fill difference norm: ", norm(gt_df[col] - df[col]))
            tmp = deepcopy(df_cp[col])
            tmp[na_inds] = mean(removeNA(tmp))
            println("GT optNA-fill difference norm:   ", norm(gt_df[col] - tmp))
        end
        println("\n")
    end
end


function run_test(dataset_str::String, excl=[], NAratio=.15)
## test setup
    #srand(1)
    # Fertility ~ Agriculture + Examination + Education + Catholic + Infant.Mortality
    ds = data("datasets", "swiss")
    clean_df!(ds)
    ds_copy = deepcopy(ds)
    #@assert length(excl) > 0, "Need to exclude the desired response variable"
    addNAs!(ds, excl, NAratio)
    # do NA-filling
    testfillNA(ds, ds_copy, excl)
end


## Do testing
run_test("swiss", ["Fertility"])
## TEST ON HS/imports-85.data
## link: http://archive.ics.uci.edu/ml/datasets/Automobile

## get some others too!!


# FULL Fertility model
# fit = lm(Formula(parse(string("Fertility ~ ", join(filter(c -> !in(c, ["", "Fertility"]), colnames(swiss)), " + ")))), swiss)
