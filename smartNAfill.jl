using DataFrames
using RDatasets
using GLM


# Fertility ~ Agriculture + Examination + Education + Catholic + Infant.Mortality
swiss = data("datasets", "swiss")

## FUNCTION
df = swiss
response = "Fertility"

clean_colnames!(df)
(m,n) = size(df)
means = Dict{Union(UTF8String,ASCIIString),Float64}()
stds  = Dict{Union(UTF8String,ASCIIString),Float64}()
fits  = Dict{Union(UTF8String,ASCIIString),LmMod}()

srand(1)
    
# insert NAs to feature vectors (not into Fertility, the response variable)
cols = filter(c -> !(c in ["", response]), colnames(df))
for col in cols
    for _ in 1:10
        df[col][ceil(rand()*m)] = NA
    end
end

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

##/FUNCTION
