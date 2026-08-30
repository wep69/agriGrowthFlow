# agriGrowthFlow 0.2.0: Final Static Validation

## Status

- Final static validation in the current build environment: **200 PASS, 0 FAIL**.
- The current environment does not contain an R executable. Therefore this report does not claim that `R CMD build`, `R CMD check --as-cran`, roxygen regeneration, testthat execution, or vignette rendering were executed.
- The frozen artifact is a source snapshot. A true R-built release tarball remains contingent on the local R validation commands below.

## Checks performed

The static battery checks package metadata, exported API definitions, S3 registration, delimiter balance, manual aliases, vignette depth, bibliography cross-links, two-source reference-audit records, teaching-data schemas and hierarchy, known-truth equations, 0.1.0 regression safeguards, 0.2.0 parametric safeguards, test-source presence, API example coverage, and source-tree hygiene.

## Results

| Status | Check | Detail |
|---|---|---|
| PASS | DESCRIPTION contains Package: agriGrowthFlow |  |
| PASS | DESCRIPTION contains Version: 0.2.0 |  |
| PASS | DESCRIPTION contains License: MIT + file LICENSE |  |
| PASS | DESCRIPTION contains Depends: R (>= 4.2.0) |  |
| PASS | DESCRIPTION title length suitable for CRAN-style metadata | 63 characters |
| PASS | Optional minpack.lm declared under Suggests |  |
| PASS | README identifies version 0.2.0 |  |
| PASS | NEWS begins with version 0.2.0 |  |
| PASS | CITATION identifies version 0.2.0 |  |
| PASS | Public API export count | 30 exports |
| PASS | Exported function defined: growth_agr |  |
| PASS | Exported function defined: growth_allometry |  |
| PASS | Exported function defined: growth_cgr |  |
| PASS | Exported function defined: growth_classical |  |
| PASS | Exported function defined: growth_data |  |
| PASS | Exported function defined: growth_design |  |
| PASS | Exported function defined: growth_example_data |  |
| PASS | Exported function defined: growth_indices |  |
| PASS | Exported function defined: growth_lad |  |
| PASS | Exported function defined: growth_lai |  |
| PASS | Exported function defined: growth_lar |  |
| PASS | Exported function defined: growth_lmr |  |
| PASS | Exported function defined: growth_nar |  |
| PASS | Exported function defined: growth_partition |  |
| PASS | Exported function defined: growth_plan |  |
| PASS | Exported function defined: growth_plot |  |
| PASS | Exported function defined: growth_rgr |  |
| PASS | Exported function defined: growth_sla |  |
| PASS | Exported function defined: growth_validate |  |
| PASS | Exported function defined: growth_models |  |
| PASS | Exported function defined: growth_start |  |
| PASS | Exported function defined: growth_fit |  |
| PASS | Exported function defined: growth_multistart |  |
| PASS | Exported function defined: growth_predict |  |
| PASS | Exported function defined: growth_compare |  |
| PASS | Exported function defined: growth_diagnose |  |
| PASS | Exported function defined: growth_traits |  |
| PASS | Exported function defined: growth_inflection |  |
| PASS | Exported function defined: growth_maxrate |  |
| PASS | Exported function defined: growth_time_to |  |
| PASS | S3 method defined: as.data.frame.agri_growth_data |  |
| PASS | S3 method defined: coef.agri_growth_fit |  |
| PASS | S3 method defined: plot.agri_growth_fit |  |
| PASS | S3 method defined: print.agri_growth_allometry |  |
| PASS | S3 method defined: print.agri_growth_comparison |  |
| PASS | S3 method defined: print.agri_growth_data |  |
| PASS | S3 method defined: print.agri_growth_design |  |
| PASS | S3 method defined: print.agri_growth_diagnostics |  |
| PASS | S3 method defined: print.agri_growth_fit |  |
| PASS | S3 method defined: print.agri_growth_fit_collection |  |
| PASS | S3 method defined: print.agri_growth_fit_set |  |
| PASS | S3 method defined: print.agri_growth_indices |  |
| PASS | S3 method defined: print.agri_growth_partition |  |
| PASS | S3 method defined: print.agri_growth_plan |  |
| PASS | S3 method defined: print.agri_growth_start |  |
| PASS | S3 method defined: print.agri_growth_validation |  |
| PASS | R delimiter balance: classical-rates.R |  |
| PASS | R delimiter balance: classical-workflow.R |  |
| PASS | R delimiter balance: growth-data.R |  |
| PASS | R delimiter balance: growth-design.R |  |
| PASS | R delimiter balance: model-registry.R |  |
| PASS | R delimiter balance: parametric-diagnostics.R |  |
| PASS | R delimiter balance: parametric-fit.R |  |
| PASS | R delimiter balance: parametric-predict-compare.R |  |
| PASS | R delimiter balance: parametric-prep-start.R |  |
| PASS | R delimiter balance: parametric-traits.R |  |
| PASS | R delimiter balance: partition-allometry.R |  |
| PASS | R delimiter balance: plot.R |  |
| PASS | R delimiter balance: utils.R |  |
| PASS | Manual alias present: growth_agr |  |
| PASS | Manual alias present: growth_allometry |  |
| PASS | Manual alias present: growth_cgr |  |
| PASS | Manual alias present: growth_classical |  |
| PASS | Manual alias present: growth_data |  |
| PASS | Manual alias present: growth_design |  |
| PASS | Manual alias present: growth_example_data |  |
| PASS | Manual alias present: growth_indices |  |
| PASS | Manual alias present: growth_lad |  |
| PASS | Manual alias present: growth_lai |  |
| PASS | Manual alias present: growth_lar |  |
| PASS | Manual alias present: growth_lmr |  |
| PASS | Manual alias present: growth_nar |  |
| PASS | Manual alias present: growth_partition |  |
| PASS | Manual alias present: growth_plan |  |
| PASS | Manual alias present: growth_plot |  |
| PASS | Manual alias present: growth_rgr |  |
| PASS | Manual alias present: growth_sla |  |
| PASS | Manual alias present: growth_validate |  |
| PASS | Manual alias present: growth_models |  |
| PASS | Manual alias present: growth_start |  |
| PASS | Manual alias present: growth_fit |  |
| PASS | Manual alias present: growth_multistart |  |
| PASS | Manual alias present: growth_predict |  |
| PASS | Manual alias present: growth_compare |  |
| PASS | Manual alias present: growth_diagnose |  |
| PASS | Manual alias present: growth_traits |  |
| PASS | Manual alias present: growth_inflection |  |
| PASS | Manual alias present: growth_maxrate |  |
| PASS | Manual alias present: growth_time_to |  |
| PASS | Twelve version 0.2.0 vignettes present | 12 found |
| PASS | Vignette instructional depth: v00-overview.Rmd | 275 lines; threshold 100 |
| PASS | Vignette instructional depth: v01-data-design-validation.Rmd | 163 lines; threshold 100 |
| PASS | Vignette instructional depth: v02-classical-growth-analysis.Rmd | 134 lines; threshold 100 |
| PASS | Vignette instructional depth: v03-leaf-traits-and-canopy.Rmd | 132 lines; threshold 100 |
| PASS | Vignette instructional depth: v04-crop-growth-integrals.Rmd | 110 lines; threshold 100 |
| PASS | Vignette instructional depth: v05-partitioning-allometry.Rmd | 130 lines; threshold 100 |
| PASS | Vignette instructional depth: v06-foundations-to-advanced-tutorial.Rmd | 615 lines; threshold 500 |
| PASS | Vignette instructional depth: v07-parametric-model-library.Rmd | 327 lines; threshold 300 |
| PASS | Vignette instructional depth: v08-starting-values-and-multistart.Rmd | 353 lines; threshold 300 |
| PASS | Vignette instructional depth: v09-model-comparison-diagnostics.Rmd | 343 lines; threshold 300 |
| PASS | Vignette instructional depth: v10-derived-growth-traits.Rmd | 347 lines; threshold 300 |
| PASS | Vignette instructional depth: v11-parametric-growth-workflow.Rmd | 1200 lines; threshold 1000 |
| PASS | Vignette bibliography present |  |
| PASS | Vignette citation key present in bibliography: AntenAckerly2001 |  |
| PASS | Vignette citation key present in bibliography: ArchontoulisMiguez2015 |  |
| PASS | Vignette citation key present in bibliography: GoudriaanMonteith1990 |  |
| PASS | Vignette citation key present in bibliography: Hunt1990 |  |
| PASS | Vignette citation key present in bibliography: KeulsGarretsen1982 |  |
| PASS | Vignette citation key present in bibliography: Poorter1989 |  |
| PASS | Vignette citation key present in bibliography: Richards1959 |  |
| PASS | Vignette citation key present in bibliography: ShipleyHunt1996 |  |
| PASS | Vignette citation key present in bibliography: YinEtAl2003 |  |
| PASS | Vignette citation key present in bibliography: YinEtAl2003Erratum |  |
| PASS | At least ten references have two-source audit records | 10 rows |
| PASS | All reference verification rows marked MATCH |  |
| PASS | All 0.2.0 core references appear in verification CSV |  |
| PASS | Teaching dataset present: maize_destructive.csv |  |
| PASS | Teaching dataset row count: maize_destructive.csv | 144 rows |
| PASS | Teaching dataset present: bean_repeated.csv |  |
| PASS | Teaching dataset row count: bean_repeated.csv | 192 rows |
| PASS | Teaching dataset present: soybean_partition.csv |  |
| PASS | Teaching dataset row count: soybean_partition.csv | 50 rows |
| PASS | Teaching dataset present: sunflower_sigmoid.csv |  |
| PASS | Teaching dataset row count: sunflower_sigmoid.csv | 216 rows |
| PASS | Teaching dataset present: wheat_expolinear.csv |  |
| PASS | Teaching dataset row count: wheat_expolinear.csv | 192 rows |
| PASS | bean_repeated schema matches repeated phenotyping example |  |
| PASS | sunflower sigmoid schema valid |  |
| PASS | wheat expolinear schema valid |  |
| PASS | Sunflower dataset has 12 stable plots |  |
| PASS | Sunflower has 108 plot-time means before aggregation |  |
| PASS | Sunflower has two destructive subsamples per plot-time |  |
| PASS | Wheat dataset has 12 stable plots |  |
| PASS | Wheat has 96 plot-time means before aggregation |  |
| PASS | Bean repeated data have 32 stable plants x 6 times |  |
| PASS | Soybean partition components close to total mass | max deviation 2.14e-07 |
| PASS | Logistic midpoint equals half asymptote |  |
| PASS | Gompertz inflection response equals A/e |  |
| PASS | Richards shape=1 equals logistic parameterization |  |
| PASS | Corrected beta growth satisfies W(0)=0 and W(te)=wmax |  |
| PASS | Expolinear late finite-difference slope approaches cm | 11.9999999966 |
| PASS | AGR known truth |  |
| PASS | RGR known truth |  |
| PASS | NAR known truth finite and positive |  |
| PASS | Classical functions use explicit recycling guard |  |
| PASS | Same-observation comparison key implemented |  |
| PASS | Ambiguous recycling stop message implemented |  |
| PASS | Longitudinal NLS limitation warning implemented |  |
| PASS | Beta public/internal constraint documented in implementation |  |
| PASS | Stable derived-trait alias implemented |  |
| PASS | Observed-support AUC alias implemented |  |
| PASS | Optional backend checked without automatic installation |  |
| PASS | Package source does not install dependencies automatically |  |
| PASS | Required test files present | test-classical-rates.R, test-classical-workflow.R, test-data-design.R, test-foundation-regressions-020.R, test-parametric-models.R, test-parametric-traits.R, test-partition-allometry.R |
| PASS | API examples include at least three calls: growth_agr | 3 calls |
| PASS | API examples include at least three calls: growth_allometry | 3 calls |
| PASS | API examples include at least three calls: growth_cgr | 3 calls |
| PASS | API examples include at least three calls: growth_classical | 3 calls |
| PASS | API examples include at least three calls: growth_data | 5 calls |
| PASS | API examples include at least three calls: growth_design | 5 calls |
| PASS | API examples include at least three calls: growth_example_data | 8 calls |
| PASS | API examples include at least three calls: growth_indices | 3 calls |
| PASS | API examples include at least three calls: growth_lad | 3 calls |
| PASS | API examples include at least three calls: growth_lai | 3 calls |
| PASS | API examples include at least three calls: growth_lar | 3 calls |
| PASS | API examples include at least three calls: growth_lmr | 3 calls |
| PASS | API examples include at least three calls: growth_nar | 3 calls |
| PASS | API examples include at least three calls: growth_partition | 3 calls |
| PASS | API examples include at least three calls: growth_plan | 3 calls |
| PASS | API examples include at least three calls: growth_plot | 3 calls |
| PASS | API examples include at least three calls: growth_rgr | 3 calls |
| PASS | API examples include at least three calls: growth_sla | 3 calls |
| PASS | API examples include at least three calls: growth_validate | 3 calls |
| PASS | API examples include at least three calls: growth_models | 4 calls |
| PASS | API examples include at least three calls: growth_start | 3 calls |
| PASS | API examples include at least three calls: growth_fit | 3 calls |
| PASS | API examples include at least three calls: growth_multistart | 3 calls |
| PASS | API examples include at least three calls: growth_predict | 3 calls |
| PASS | API examples include at least three calls: growth_compare | 3 calls |
| PASS | API examples include at least three calls: growth_diagnose | 3 calls |
| PASS | API examples include at least three calls: growth_traits | 3 calls |
| PASS | API examples include at least three calls: growth_inflection | 3 calls |
| PASS | API examples include at least three calls: growth_maxrate | 3 calls |
| PASS | API examples include at least three calls: growth_time_to | 3 calls |
| PASS | Repeated-bean examples use actual dataset columns |  |
| PASS | No em dash in package prose/source |  |
| PASS | No ChatGPT/UI citation artifacts in distributed files |  |
| PASS | No provisional TODO/FIXME/placeholder markers |  |
| PASS | No Python cache directories in source tree |  |
| PASS | Teaching-data SHA256 manifest refreshed | inst/metadata/teaching_data_checksums.sha256 |

## Required local R release gates

Run from a clean machine with R >= 4.2.0:

```r
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "ggplot2", "rlang", "minpack.lm"))
devtools::document("agriGrowthFlow")
devtools::test("agriGrowthFlow")
devtools::install("agriGrowthFlow", build_vignettes = TRUE)
devtools::check("agriGrowthFlow", cran = TRUE, manual = TRUE)
```

Then build and check the exact immutable tarball:

```sh
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_0.2.0.tar.gz
```

## High-priority numerical controls for the local run

1. Logistic midpoint must equal half asymptote.
2. Gompertz inflection response must equal `A/e`.
3. Richards with `shape = 1` must reproduce the package logistic curve.
4. Corrected beta growth must satisfy `W(0) = 0` and `W(te) = wmax`.
5. Expolinear late finite-difference slope must approach `cm`.
6. Known noiseless logistic data must recover their generating coefficients.
7. Candidate comparison must normalize finite AICc weights to one.
8. Destructive sunflower subsamples must reduce from 216 rows to 108 plot-time means before fitting when all cultivars are retained.
9. Grouped trait extraction must return a data frame with a `group` column.
10. Confidence and prediction intervals must preserve lower <= fit <= upper, with prediction intervals no narrower than confidence intervals at the same times.
11. Ambiguous vector recycling in classical 0.1.0 functions must raise an error.

## Interpretation

A zero-failure static battery establishes internal source coherence at the level tested here. It is not a substitute for parsing, executing, compiling documentation, and checking the package with R. The source snapshot can be frozen and hashed, but it should not be represented as an `R CMD build` artifact until the local R gates succeed.
