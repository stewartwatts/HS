using DataFrames
using RDatasets
using GLM

# test setup
srand(1)
# Fertility ~ Agriculture + Examination + Education + Catholic + Infant.Mortality
swiss = data("datasets", "swiss")
swiss_copy = deepcopy(swiss)
exclude_colnames = ["Fertility"]

# insert NAs to feature vectors (not into Fertility, the response variable)
cols = filter(c -> !(c in ["" exclude_colnames]), num_cols)
for col in cols
    for _ in 1:10
        df[col][ceil(rand()*m)] = NA
    end
end

# do NA-filling
optNAfill!(df, exclude_columns)

# test performance  ...
