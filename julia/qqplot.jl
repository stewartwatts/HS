using Stats, Distributions, Vega
 
Vega.plot(qq::QQPair) = Vega.plot(x = qq.qx, y = qq.qy, kind = :scatter)
 
qqplot(x::Vector, y::Vector) = plot(qqbuild(x, y))
qqplot(x::Vector, d::UnivariateDistribution) = plot(qqbuild(x, d))
qqplot(d::UnivariateDistribution, x::Vector) = plot(qqbuild(d, x))
 
x = rand(Normal(), 10_000)
y = rand(Cauchy(), 10_000)
 
plot(qqbuild(x, y))
qqplot(x, y)
qqplot(y, x)
 
plot(qqbuild(x, Normal()))
qqplot(x, Normal())
qqplot(x, Normal(0, 10))
qqplot(x, Cauchy())
qqplot(Cauchy(), x)
qqplot(x, Laplace())
qqplot(Laplace(), x)
