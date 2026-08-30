# agriGrowthFlow 0.2.0 Freeze Manifest

**Version:** 0.2.0  
**Freeze date:** 2026-08-27  
**Artifact type:** frozen source snapshot  
**R-built tarball:** no, because an R executable is not available in the current environment

## Freeze decision

The 0.2.0 source tree is frozen after correction of the remaining 0.1.0 maintenance items and completion of the parametric-growth layer. The final static validation battery reports **200 PASS and 0 FAIL**.

This freeze means that the source files, simulated teaching data, tests, manual pages, reference audit, and vignettes have been made internally consistent at the level that can be checked without R. It does not replace `R CMD build` or `R CMD check --as-cran`.

## Corrections completed before freeze

- Reconstructed the complete package tree from the preserved 0.1.0 source snapshot and merged the 0.2.0 implementation rather than freezing the previously incomplete sparse directory.
- Updated package metadata, citation information, NAMESPACE, manuals, README, and NEWS to version 0.2.0.
- Added explicit vector-length compatibility checks to classical vectorized growth functions so ambiguous R vector recycling is rejected.
- Added `print.agri_growth_partition()`.
- Corrected repeated-bean examples to use the actual `water_regime` and `projected_leaf_area_m2` columns.
- Added the complete eight-model parametric registry: logistic, Gompertz, Richards, Chapman-Richards, Weibull, von Bertalanffy, corrected beta growth, and expolinear.
- Added automatic starts, hard bounds, multistart audit, bounded base-R NLS, and optional `minpack.lm` support without automatic dependency installation.
- Preserved destructive-sampling aggregation at persistent experimental-unit by time level before parametric fitting.
- Added same-observation model-comparison protection.
- Added boundary-aware numerical gradients for local delta-method prediction intervals.
- Added unit-aware residual lag diagnostics that do not connect unrelated experimental units.
- Standardized grouped trait extraction to a data frame with stable columns, including `maximum_absolute_rate`, `auc_observed_support`, `support_min`, and `support_max`.
- Added explicit zero-target conventions and prevented fractional-asymptote targets for expolinear growth.
- Added simulated sunflower sigmoid and wheat expolinear teaching datasets.
- Added five extensive 0.2.0 vignettes while retaining the seven extensive 0.1.0 foundation vignettes.
- Removed ChatGPT/UI citation artifacts from distributed vignette source.
- Added 0.2.0 unit-test source files and a public API example file with at least three usage patterns for every exported function.
- Expanded the double-source reference audit to the nonlinear-growth references used by 0.2.0.

## Static validation result

See `LOCAL_VALIDATION_0.2.0.md` for the complete table.

Final result in this environment:

- **200 PASS**
- **0 FAIL**

The static battery covers metadata, API definitions, S3 registration, delimiter balance, manual aliases, vignette depth, bibliography cross-links, reference-audit records, teaching-data hierarchy, known-truth mathematical identities, 0.1.0 regression safeguards, 0.2.0 numerical safeguards, test-source presence, API-example coverage, and source-tree hygiene.

## Scientific controls included

The frozen tree contains checks for the following identities and behaviors:

1. logistic response at `mid` equals half the asymptote;
2. Gompertz response at its inflection equals `A/e`;
3. Richards with `shape = 1` reproduces the package logistic curve;
4. corrected beta growth satisfies `W(0) = 0` and `W(te) = wmax`;
5. the late finite-difference slope of expolinear growth approaches `cm`;
6. noiseless logistic data recover their generating parameters in the R test source;
7. model comparison is restricted to identical prepared observations;
8. destructive subsamples are aggregated at persistent unit by time before fitting;
9. grouped traits retain the group identifier and a stable tabular schema;
10. prediction intervals are defined separately from mean-curve confidence intervals;
11. classical functions reject ambiguous vector recycling.

## References

`REFERENCE_AUDIT_0.2.0.md` and `inst/metadata/reference_verification.csv` record two-source metadata checks for the core foundation and 0.2.0 references. The corrected beta-growth exponent follows the published Yin et al. erratum.

## Documentation

The frozen tree contains 12 English vignettes. The principal integrated tutorials are:

- `v06-foundations-to-advanced-tutorial.Rmd`
- `v11-parametric-growth-workflow.Rmd`

The 0.2.0 model-specific sequence is `v07` through `v11`.

## Remaining release gate

The only unresolved release gate is execution in an environment with R >= 4.2.0. Before assigning a CRAN-like release status, run:

```r
install.packages(c(
  "devtools", "roxygen2", "testthat", "knitr", "rmarkdown",
  "ggplot2", "rlang", "minpack.lm"
))
devtools::document("agriGrowthFlow")
devtools::test("agriGrowthFlow")
devtools::install("agriGrowthFlow", build_vignettes = TRUE)
devtools::check("agriGrowthFlow", cran = TRUE, manual = TRUE)
```

Then build and check the exact source tarball:

```sh
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_0.2.0.tar.gz
```

## Integrity files

- `TREE_0.2.0.txt` lists the frozen source-tree files.
- `SHA256SUMS_0.2.0.txt` stores SHA-256 hashes for source files, excluding the checksum file itself.
- Archive-level SHA-256 hashes are distributed in the external companion checksum file alongside the ZIP and TAR.GZ snapshots.
