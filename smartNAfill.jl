using DataFrames
using RDatasets
using GLM

# globals
POLYDEG = 2     # polynomial degree of feature models
NOISE   = 0.25  # std of added noise

# "swiss" dataset for modeling:: Fertility ~ Agriculture + Examination + Education + Catholic + Infant.Mortality
swiss = data("datasets", "swiss")

################## would be function START
df = swiss
response = "Fertility"

clean_colnames!(df)
(m,n) = size(df)
means, stds, fits = {}, {}, {}

srand(1)
    
# insert NAs to feature vectors (not into Fertility, the repsponse variable)
cols = filter(c -> !(c in ["", response]), colnames(df))
for col in cols
    for _ in 1:10
        df[col][int(rand()*m)+1] = NA
    end
end

# do smart inference of missing values
# first recenter / rescale
for col in cols
    colmean = mean(removeNA(df[col]))
    colstd  = std(removeNA(df[col]))
    df[col] = (df[col] - colmean) / colstd
    means[col] = colmean
    stsd[col] = colstd
end

# model each column on other features
for col in cols
    fits[col] = lm(Formula(parse(string(col, " ~ ", join(filter(k -> k != col, cols), " + ")))), df)
end












################## would be function END



#### for some reason the above code does not work as a function
##
##smartNAfill(swiss, "Fertility")
##ERROR: BoundsError()
##in setindex! at bitarray.jl:534
##in setindex! at /home/stewart/.julia/DataFrames/src/dataarray.jl:487
##in smartNAfill at none:17 

#function smartNAfill(df::DataFrame, response::Union(UTF8String,ASCIIString))
#end
