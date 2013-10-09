using DataFrames
using RDatasets
using GLM

function clean_df!{T<:String}(df::AbstractDataFrame, exclude_colnames::Array{T,1})
    clean_colnames!(df)
    exclude_colnames = ["" exclude_colnames]
    cns = filter(c -> !in(exclude_colnames, c), colnames(df))
    # promotion to Float
    num_cols = filter(c -> eltype(df[c]) <: Number, cns)
    for col in num_cols
        df[col] = etype(df[col]) <: FloatingPoint ? df[col] : 1.0 * df[col]
    end
    return
end

function optNAFill!{T<:String}(df::AbstractDataFrame, exclude_colnames::Array{T,1})
    #optimistic NA filling

    (m,n) = size(df)
    means = Dict{Union(UTF8String,ASCIIString),Float64}()
    stds  = Dict{Union(UTF8String,ASCIIString),Float64}()
    fits  = Dict{Union(UTF8String,ASCIIString),LmMod}()
    

    # model each column on other features
    for col in cols
        fits[col] = lm(Formula(parse(string(col, " ~ ", join(filter(k -> k != col, cols), " + ")))), df)
    end

    # collect col stats
    for col in cols
        colmean = mean(removeNA(df[col]))
        colstd  = std(removeNA(df[col]))
        df[col] = (df[col] - colmean) / colstd
        means[col] = colmean
        stsd[col] = colstd
    end    
end  # of function optNAfill
