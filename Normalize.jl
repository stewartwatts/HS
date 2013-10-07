# inspiration: http://blog.explainmydata.com/2012/07/should-you-apply-pca-to-your-data.html
module Preprocess

using DataFrames
using DimensionalityReduction

export PreprocessRoutine

type PreprocessRoutine
    
end

# 0. scan a dataframe for numerical features that look problematic
#    - strongly non-Gaussian, discontinuous, heavily quantized, log-scale, too many NA
#    - give helpful warnings or suggested


# 1. PCA on centered data
f1 = df_pca;

# 2. PCA on sphered data (each dimension zero mean, unit variance)
function f2(num_X::DataFrame, cutoff=0.99)
    for cn in colnames(num_X)
        num_X[cn] = (num_X[cn] - mean(num_X[cn])) / std(num_X[cn])
    end
    df_pca(num_X)
end

# 3. PCA on [-1 : 1] normalized data


# 4. ZCA whitening on raw data (rotation + scaling --> identity covariance)

# 5. PCA on ZCA-whitened data

# 6. wrapper for the above functionality

# 7. 

end

