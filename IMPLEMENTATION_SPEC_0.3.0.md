# agriGrowthFlow 0.3.0 Implementation Specification

## Release objective

Extend the complete 0.1.0 Foundations and 0.2.0 Parametric Growth Models layers with design-aware longitudinal, flexible, functional, and multivariate growth analysis. Version 0.3.0 addresses within-unit dependence and trajectory-shape flexibility without silently replacing hierarchical inference with pooled smooths or forcing irregular curves onto a common grid by extrapolation.

## Public API added in 0.3.0

| Function | Main responsibility | Principal output |
|---|---|---|
| `growth_mixed()` | polynomial mixed-effects growth analysis with persistent-unit random effects | `agri_growth_mixed` |
| `growth_mixed_diagnose()` | residual, fit, and within-unit serial-dependence diagnostics | `agri_growth_mixed_diagnostics` |
| `growth_smooth()` | descriptive flexible trajectory estimation | `agri_growth_smooth` / collection |
| `growth_smooth_predict()` | evaluate flexible trajectories on requested support | data frame |
| `growth_derivative()` | first or second derivative of a smooth trajectory | data frame |
| `growth_acceleration()` | convenience wrapper for the second derivative | data frame |
| `growth_smooth_traits()` | numerical growth landmarks from flexible trajectories | data frame |
| `growth_fpca()` | functional principal component analysis of persistent-unit trajectories | `agri_growth_fpca` |
| `growth_functional()` | alias for functional growth analysis | `agri_growth_fpca` |
| `growth_curve_coefficients()` | orthogonal polynomial coefficients per persistent experimental unit | data frame |
| `growth_manova()` | MANOVA comparison of unit-level growth-curve components | `agri_growth_manova` |

The total exported public API after consolidation is 41 functions.

## Longitudinal mixed-effects layer

### Engine

`growth_mixed()` uses `nlme::lme()` when the optional `nlme` package is installed. No dependency is installed automatically.

### Fixed trajectory

Time is represented with orthogonal polynomial terms using `poly(.t, degree, raw = FALSE)`. A declared treatment group is interacted with the time trajectory. A declared block is included as a fixed adjustment term when it has more than one level.

### Random trajectory

`random_degree = 0` fits a random intercept. Positive values add orthogonal polynomial random time terms within the persistent unit. The requested random degree cannot exceed the fixed degree.

### Correlation structures

- `"none"`: no explicit residual serial-correlation structure;
- `"ar1"`: `nlme::corAR1()` and integer-valued time only;
- `"car1"`: `nlme::corCAR1()` for continuous or irregular elapsed time.

The package rejects discrete AR(1) when the supplied time variable is noninteger and directs the user to continuous-time AR(1).

### Residual variance structures

- `"none"`;
- `"power"`: `varPower()` of fitted values;
- `"exponential"`: `varExp()` of fitted values;
- `"group"`: `varIdent()` across declared growth groups;
- `"time"`: `varIdent()` across observed time levels.

These alternatives are user-specified scientific models. Version 0.3.0 does not select them only by a p-value.

### Design safeguard

For declared destructive sampling with `aggregate = "auto"`, observations are first averaged within persistent experimental unit, group, block, and time. Different plants removed at successive harvests are therefore not mislabeled as repeatedly measured individuals.

## Flexible trajectory layer

### Engines

1. `smooth_spline`: `stats::smooth.spline()`;
2. `loess`: `stats::loess()`;
3. `gam`: optional `mgcv::gam()`;
4. `scam`: optional `scam::scam()`.

### Population weighting

When a persistent unit is supplied, technical replicates or duplicate observations are first reduced within unit by time. Population trajectories are then formed from unit-level values. This prevents units with more records at one time from receiving unintended extra weight.

### Shape constraints

SCAM monotonicity is opt-in:

- `constraint = "increasing"` uses a monotone increasing smooth basis;
- `constraint = "decreasing"` uses a monotone decreasing smooth basis.

The package never assumes monotonicity solely because the response is called growth.

### Derivatives

Smoothing-spline derivatives use the native derivative calculation from `predict.smooth.spline()`. LOESS, GAM, and SCAM derivatives are evaluated with support-aware finite differences, using central formulas in the interior and one-sided formulas near boundaries. Derivatives are not evaluated by uncontrolled extrapolation beyond observed support.

### Smooth traits

`growth_smooth_traits()` reports the numerical maximum first derivative, its time, peak fitted response, its time, number of detected second-derivative sign changes, and approximate inflection times. These are descriptive smooth landmarks rather than bootstrap- or Bayesian-calibrated quantities.

## Functional growth layer

### Built-in grid FPCA

The `grid` engine:

1. requires a persistent unit and at least three observations per unit;
2. finds the intersection of unit-specific observed time ranges;
3. refuses analysis when no positive common support exists;
4. reconstructs each unit only inside that common support using smoothing splines or linear interpolation;
5. applies an L2 discretization weight based on grid spacing;
6. performs PCA on centered weighted curves;
7. returns scores, eigenfunctions, eigenvalues, PVE, mean curve, and support.

The built-in engine deliberately favors transparent common-support analysis over silent extrapolation.

### Optional sparse/irregular engines

- `fdapace::FPCA()` receives list-form irregular observations. FVE chooses component count when `npc` is omitted; a positive fixed `methodSelectK` is used when `npc` is supplied.
- `refund::fpca.sc()` receives long-form `.id`, `.index`, `.value` data and uses `pve` unless `npc` overrides it.

Group labels are retained with score tables only when group is invariant within each persistent unit.

## Orthogonal growth components and MANOVA

`growth_curve_coefficients()` reduces each persistent unit to an intercept-like level coefficient and orthogonal polynomial components `P1 ... Pk` on a common observed time grid. The method:

- aggregates destructive subsamples first under the automatic rule;
- requires group identity to be invariant within unit;
- requires every unit to have exactly the same observed time grid;
- refuses silent interpolation of missing harvests;
- optionally log-transforms strictly positive responses.

`growth_manova()` applies MANOVA to the coefficient matrix and supports Pillai, Wilks, Hotelling-Lawley, and Roy statistics. Component-wise ANOVAs are returned with the multivariate test.

## Simulated teaching data added in 0.3.0

`soybean_irregular.csv` contains 402 simulated records from 48 persistent soybean plants, two water regimes, and irregular subsets of 11 potential observation days. Each plant has 7 to 10 measurements. The dataset is intended for CAR(1), smoothing, and functional-data examples. It is explicitly teaching data and is not empirical evidence.

## Public documentation

Version 0.3.0 retains the 12 vignettes from earlier layers and adds six extensive English vignettes:

1. `v12-longitudinal-mixed-effects.Rmd`;
2. `v13-flexible-smoothing-derivatives.Rmd`;
3. `v14-shape-constrained-growth.Rmd`;
4. `v15-functional-growth-fpca.Rmd`;
5. `v16-multivariate-growth-manova.Rmd`;
6. `v17-longitudinal-flexible-workflow.Rmd`.

The integrated `v17` tutorial exceeds 1,000 lines and connects design declaration, longitudinal dependence, flexible trajectories, derivatives, functional decomposition, MANOVA, interpretation, and reporting.

`inst/examples/API_EXAMPLES_0.3.0.R` consolidates all 41 exported functions and provides at least three call patterns for each public function. Optional-engine examples are guarded with `requireNamespace()` where execution would otherwise require an optional package.

## Reference requirements

The package bibliography contains 16 core records. Every record has a two-source verification row in `inst/metadata/reference_verification.csv`; all citation keys used in vignettes resolve to `vignettes/references.bib`. `REFERENCE_AUDIT_0.3.0.md` documents the five references introduced for the new layer.

## Static synchronization requirements

Before freezing the source snapshot:

- `DESCRIPTION`, README, NEWS, and `inst/CITATION` must identify 0.3.0;
- every `NAMESPACE` export must have a function definition and a manual alias;
- every registered S3 method must have a corresponding function definition;
- the new `growth_smooth()` manual must include the `unit` argument present in source;
- all 18 vignette citation keys must resolve;
- all new test files must be present;
- all six teaching datasets must have refreshed SHA-256 hashes;
- source files must contain no provisional work markers or ChatGPT UI citation artifacts.

## Testing requirements

In addition to every 0.1.0 and 0.2.0 regression control, version 0.3.0 adds source tests for:

- preservation of the 32-plant repeated hierarchy in mixed models;
- destructive aggregation from 144 maize rows to 72 plot-time means;
- rejection of discrete AR(1) on noninteger time;
- unit-aware mixed-model residual diagnostics;
- grouped population smooths;
- first derivative of a known linear trajectory;
- near-zero second derivative of a known linear trajectory;
- smooth-trait output structure;
- grid-FPCA scores and cumulative PVE;
- refusal of non-overlapping functional support;
- 48 persistent units in the irregular soybean teaching data;
- orthogonal coefficient extraction at plot level;
- MANOVA output structure;
- refusal of missing common harvest grids;
- guarded log transformation.

## Release limitation in the current environment

The current environment does not contain an R executable. Static validation can therefore establish source-tree coherence, documentation synchronization, mathematical/data invariants accessible without R, example coverage, test-source presence, and archive integrity. It cannot honestly claim execution of roxygen2, testthat, vignette rendering, `R CMD build`, or `R CMD check --as-cran`.

The frozen 0.3.0 artifacts are consequently labeled **frozen source snapshots**. A true R-built release tarball remains contingent on the local R gates recorded in `LOCAL_VALIDATION_0.3.0.md`.

## Deferred capabilities

Version 0.3.0 deliberately defers:

- bootstrap uncertainty for curve traits and smooth landmarks;
- Bayesian hierarchical nonlinear growth models;
- model averaging across uncertainty frameworks;
- diphasic/multiphase nonlinear sums and segmented nonlinear growth;
- explicit discontinuity/event models for defoliation and harvest loss;
- mechanistic competition ODEs and cellular-automata coupling.

These capabilities belong to later versions rather than being approximated silently in 0.3.0.
