## agriGrowthFlow 1.0.0

This is the first consolidated stable release of agriGrowthFlow.

The source snapshot distributed from the development environment has been statically validated, but the development environment does not contain R. Before CRAN submission, the exact R-built tarball must be produced and checked locally with:

```text
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz
```

The release contains optional analytical backends for mixed, flexible, functional, and Bayesian workflows. Optional packages are listed under Suggests and are never installed automatically. Bayesian tests are gated because they require a Stan toolchain and longer runtime.

The package includes simulated teaching datasets only. They are documented as simulated and are not presented as field evidence.
