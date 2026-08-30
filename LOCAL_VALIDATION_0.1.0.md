# agriGrowthFlow 0.1.0: Local and Static Validation

## Validation status

- Static checks executed in the build environment: **72 passed, 0 failed**.
- R is not installed in the current execution environment, so `R CMD build`, `R CMD check --as-cran`, roxygen regeneration, package installation, and vignette rendering were **not** executed here.
- The static battery checks package structure, public API consistency, delimiter balance, teaching-data hierarchy, known-truth formula calculations, reference-audit records, documentation depth, and frozen-data checksums.

## Static results

| Status | Check | Detail |
|---|---|---|
| PASS | DESCRIPTION contains Package: agriGrowthFlow |  |
| PASS | DESCRIPTION contains Version: 0.1.0 |  |
| PASS | DESCRIPTION contains License: MIT + file LICENSE |  |
| PASS | DESCRIPTION contains Depends: R (>= 4.2.0) |  |
| PASS | DESCRIPTION has no unverified repository URL |  |
| PASS | DESCRIPTION title length suitable for CRAN-style metadata | 63 characters |
| PASS | exported function defined: growth_agr |  |
| PASS | exported function defined: growth_allometry |  |
| PASS | exported function defined: growth_cgr |  |
| PASS | exported function defined: growth_classical |  |
| PASS | exported function defined: growth_data |  |
| PASS | exported function defined: growth_design |  |
| PASS | exported function defined: growth_example_data |  |
| PASS | exported function defined: growth_indices |  |
| PASS | exported function defined: growth_lad |  |
| PASS | exported function defined: growth_lai |  |
| PASS | exported function defined: growth_lar |  |
| PASS | exported function defined: growth_lmr |  |
| PASS | exported function defined: growth_nar |  |
| PASS | exported function defined: growth_partition |  |
| PASS | exported function defined: growth_plan |  |
| PASS | exported function defined: growth_plot |  |
| PASS | exported function defined: growth_rgr |  |
| PASS | exported function defined: growth_sla |  |
| PASS | exported function defined: growth_validate |  |
| PASS | Foundational public API size | 19 exported functions |
| PASS | S3 method defined: as.data.frame.agri_growth_data |  |
| PASS | S3 method defined: print.agri_growth_allometry |  |
| PASS | S3 method defined: print.agri_growth_data |  |
| PASS | S3 method defined: print.agri_growth_design |  |
| PASS | S3 method defined: print.agri_growth_indices |  |
| PASS | S3 method defined: print.agri_growth_plan |  |
| PASS | S3 method defined: print.agri_growth_validation |  |
| PASS | R delimiter balance: classical-rates.R |  |
| PASS | R delimiter balance: classical-workflow.R |  |
| PASS | R delimiter balance: growth-data.R |  |
| PASS | R delimiter balance: growth-design.R |  |
| PASS | R delimiter balance: partition-allometry.R |  |
| PASS | R delimiter balance: plot.R |  |
| PASS | R delimiter balance: utils.R |  |
| PASS | Seven version 0.1.0 vignettes present | 7 found |
| PASS | Vignette instructional depth: v00-overview.Rmd | 275 lines; threshold 100 |
| PASS | Vignette instructional depth: v01-data-design-validation.Rmd | 163 lines; threshold 100 |
| PASS | Vignette instructional depth: v02-classical-growth-analysis.Rmd | 134 lines; threshold 100 |
| PASS | Vignette instructional depth: v03-leaf-traits-and-canopy.Rmd | 132 lines; threshold 100 |
| PASS | Vignette instructional depth: v04-crop-growth-integrals.Rmd | 110 lines; threshold 100 |
| PASS | Vignette instructional depth: v05-partitioning-allometry.Rmd | 130 lines; threshold 100 |
| PASS | Vignette instructional depth: v06-foundations-to-advanced-tutorial.Rmd | 615 lines; threshold 500 |
| PASS | Vignette bibliography present |  |
| PASS | At least five foundational references audited | 5 rows |
| PASS | Reference audit rows marked matched |  |
| PASS | Teaching dataset row count: maize_destructive.csv | 144 rows |
| PASS | Teaching dataset schema: maize_destructive.csv | 12 columns |
| PASS | Teaching dataset row count: bean_repeated.csv | 192 rows |
| PASS | Teaching dataset schema: bean_repeated.csv | 7 columns |
| PASS | Teaching dataset row count: soybean_partition.csv | 50 rows |
| PASS | Teaching dataset schema: soybean_partition.csv | 10 columns |
| PASS | Destructive data stable plot x harvest combinations | 72 |
| PASS | Destructive data stable experimental units | 12 plots |
| PASS | Expected consecutive destructive intervals after aggregation | 60 plot-level intervals |
| PASS | Repeated dataset has stable plant trajectories | 32 plants x 6 times |
| PASS | Soybean component masses close to declared total mass | max /closure-1/=2.14e-07 |
| PASS | AGR known-truth calculation | 2.0 |
| PASS | RGR known-truth calculation | 0.138629436112 |
| PASS | NAR known-truth calculation | 13.862943611199 |
| PASS | NAR equal-leaf-area continuous limit | 20.0 |
| PASS | LAR = SLA x LMR identity | 0.00800000 |
| PASS | LAD trapezoidal known-truth calculation | 9.25 |
| PASS | Log-log allometry known-truth recovery | a=3; k=1.5 |
| PASS | No em dash in package prose/source |  |
| PASS | No provisional TODO/FIXME/placeholder markers |  |
| PASS | Teaching-data SHA256 manifest written | inst/metadata/teaching_data_checksums.sha256 |

## Required local R validation

Run these commands from a clean R session on a machine with R >= 4.2.0:

```r
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "ggplot2", "rlang"))
devtools::document("agriGrowthFlow")
devtools::test("agriGrowthFlow")
devtools::install("agriGrowthFlow", build_vignettes = TRUE)
devtools::check("agriGrowthFlow", cran = TRUE, manual = TRUE)
```

Then build an immutable source tarball and check that exact artifact:

```sh
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_0.1.0.tar.gz
```

## Numerical controls to verify locally

1. `growth_agr(10, 20, 0, 5)` must return `2`.
2. `growth_rgr(10, 20, 0, 5)` must return `log(2)/5`.
3. `growth_nar(10, 20, 0.1, 0.2, 0, 5)` must agree with the classical logarithmic-area formula.
4. `growth_nar(10, 20, 0.1, 0.1, 0, 5)` must use the continuous limit and return `20`.
5. `growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10))` must return `9.25`.
6. For positive leaf area, leaf mass and total mass, verify numerically that `LAR = SLA * LMR`.
7. `growth_indices()` on `maize_destructive` must first reduce 144 harvest-subsample rows to 72 plot-by-time means and then form 60 plot-level consecutive intervals.
8. Repeated data must preserve stable plant identifiers rather than being converted silently to independent time-specific means.

## Interpretation of this report

A passing static battery is evidence that the source snapshot is internally coherent. It is not a substitute for parsing and executing the package with R. The release should not be tagged as fully validated until the local R commands above complete without unresolved errors or warnings.
