using DataFrames
using RDatasets
using GLM

function clean_df!(df::AbstractDataFrame)
    clean_colnames!(df)
    
    # promotion to Float
    num_cols = filter(c -> eltype(df[c]) <: Number, colnames(df))
    for col in num_cols
        df[col] = eltype(df[col]) <: FloatingPoint ? df[col] : 1.0 * df[col]
    end

    return
end

function optNAfill(df::AbstractDataFrame; exclude_colnames=[], clean=true)
    # exclude_colnames: Array of strings containing colnames of data that can't reasonably
    #                   be inferred or created.  Ex: the response variable.  Any row with a
    #                   missing response variable should reasonably be excluded from analysis.
    
    if clean
        clean_df!(df)
    end
    df_cp = deepcopy(df)
    
    cols = filter(c -> !in(c, ["" exclude_colnames]) && eltype(df[c]) <: FloatingPoint, colnames(df))
    
    # predict NAs
    for col in cols
        colmeann = mean(removeNA(df[col]))
        colstd = std(removeNA(df[col]))
        colmin = min(removeNA(df[col]))
        colmax = max(removeNA(df[col]))
        
        other_cols = filter(c -> c != col, cols)
        # array of colnames with data -> indexes pertained to
        frms = Dict()
        preds = fill(0., sum(isna(df[col])))      # length n
        
        # predict() only works for Array of new data (no NA)
        # must fit a model for each dense-Array signiture
        ba = !isna(df[isna(df[col]), other_cols])    # n-BitArray
        for i in 1:size(ba,1)
            cns = other_cols[find(ba[i,:] .== true)] # colnames
            if haskey(frms, cns)
                frms[cns] = [frms[cns]; i]
            else
                frms[cns] = [i]
            end
        end

        for frm in keys(frms)
            fit = lm(Formula(parse(string(col, " ~ ", join(frm, " + ")))), df)
            sub_data_arr = DataArray(df[isna(df[col]), convert(Array{ASCIIString,1}, frm)][frms[frm],:])
            arr = convert(Array{Float64,2}, sub_data_arr)
            pred_cands = predict(fit, [ones(size(arr,1)) arr])

            # how good are these preds ?? backoff some to colmean given uncertainty
            
            preds[frms[frm]] = 0. # TODO
        end
        df_cp[isna(df[col]), col] = preds
    end
    return df_cp
end  
