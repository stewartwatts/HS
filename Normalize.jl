# inspiration: http://blog.explainmydata.com/2012/07/should-you-apply-pca-to-your-data.html
module Normalize

using DataFrames
using DimensionalityReduction

# 0. scan a dataframe for numerical features that look problematic
#    - strongly non-Gaussian, discontinuous, heavily quantized, log-scale
#    - give helpful warnings or suggested 

# 1. PCA on raw data

# 2. PCA on sphered data (each dimension zero mean, unit variance)

# 3. PCA on zero-to-one normalized data

# 4. ZCA whitening on raw data (rotation + scaling --> identity covariance)

# 5. PCA on ZCA-whitened data

# 6. wrapper for the above functionality

# 7. 

end

