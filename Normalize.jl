# inspiration: http://blog.explainmydata.com/2012/07/should-you-apply-pca-to-your-data.html
module Normalize

using DataFrames
using DimensionalityReduction

export NormedData

type NormedData
    X::DataFrame
    numerical_cols = filter(c -> eltype(X[c]) <: Number, colnames(X))
    other_cols = filter(c -> !(eltype(X[c]) <: Number), colnames(X))
    num_X = X[:, numerical_cols]
    oth_X = X[:, other_cols]
end

# 0. scan a dataframe for numerical features that look problematic
#    - strongly non-Gaussian, discontinuous, heavily quantized, log-scale
#    - give helpful warnings or suggested 


# 1. PCA on raw data
f1 = pca;

# 2. PCA on sphered data (each dimension zero mean, unit variance)
function f2(num_X::DataFrame)
    
end

# 3. PCA on zero-to-one normalized data

# 4. ZCA whitening on raw data (rotation + scaling --> identity covariance)

# 5. PCA on ZCA-whitened data

# 6. wrapper for the above functionality

# 7. 

end

