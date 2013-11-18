# new type for DataFrame PCA
function df_pcaeig(X::DataFrame, na_replace_func=mean)
    numerical_cols = filter(c -> eltype(X[c]) <: Number, colnames(X))

    # promote numerical cols to float
    for cn in numerical_cols
        if !(eltype(X[:, cn]) <: FloatingPoint)
            X[:, cn] *= 1.0
        end
    end

    # replaceNA to NA-removed mean
    for cn in numerical_cols
        na_replace = na_replace_func(removeNA(X[:, cn]))
        X[:, cn] = replaceNA(X[:, cn], na_replace)
    end
    
    L, Z = eig(cov(X[:, numerical_cols]))
    P = Z'
    L = reverse(L)
    for i in 1:length(L)
        L[i] = clamp(L[i], 0.0, Inf)
    end
    P = fliplr(P)
    Y = DataArray(X[:, numerical_cols]) * P
    return DF_PCA(P, Y, sqrt(L), L / sum(L), cumsum(L) / sum(L))
end
