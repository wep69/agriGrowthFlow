# agriGrowthFlow

`agriGrowthFlow` is an R package for design-aware analysis of plant growth trajectories.

## Installation

```r
remotes::install_github(
    "wep69/agriGrowthFlow",
    dependencies = TRUE,
    build_vignettes = TRUE,
    upgrade = "ask",
    force = FALSE
)
```

For a fast install without rebuilding vignettes:

```r
pak::pak("wep69/agriGrowthFlow")
```

Version 1.0.0 consolidates the complete Foundations, Parametric Growth Models, Longitudinal and Flexible Growth, Uncertainty, and Biological Events and Agronomic Decisions layers and adds an auditable release workflow. The central rule remains:

> **Define the persistent experimental unit and sampling process before fitting or interpreting a growth trajectory.**

## 1.0.0 consolidated workflow

1. declare time, sampling mechanism, persistent experimental unit, treatment, block and biological measurements;
2. validate destructive versus repeated sampling and inspect raw trajectories;
3. use classical growth indices when interval-based physiology is scientifically appropriate;
4. use parametric equations when interpretable biological parameters are justified;
5. use `growth_mixed()` when treatment comparisons require longitudinal random effects and residual covariance modeling;
6. use `growth_smooth()` when the trajectory shape should be learned flexibly rather than forced into a predefined growth equation;
7. use `growth_derivative()` and `growth_acceleration()` to study instantaneous change and changes in growth rate;
8. use monotone `scam` fits only when the biological process genuinely supports a shape constraint;
9. use `growth_fpca()` when each plant or plot is scientifically treated as a functional trajectory;
10. use `growth_manova()` when a common-time design supports comparison of orthogonal curve components at the experimental-unit level;
11. diagnose covariance assumptions, heterogeneity, support, missingness and extrapolation before making scientific claims;
12. use `growth_boot()` to propagate sampling uncertainty through nonlinear refitting with a resampling unit consistent with the design;
13. use `growth_selection_stability()` when the scientific conclusion may depend on the selected parametric family;
14. use `growth_prior()` and prior predictive simulation before Bayesian posterior interpretation;
15. use `growth_bayes_diagnose()` and posterior predictive checks as mandatory Bayesian gates;
16. use `growth_posterior_traits()` to report posterior uncertainty on biologically interpretable scales;
17. inspect Pareto-k diagnostics with `growth_loo()` before using LOO-based predictive comparison;
18. use stacking or pseudo-BMA only for models fitted to the identical prepared observations.




## Consolidated release entry point

Version 1.0.0 adds a transparent orchestration layer without hiding the specialist functions. `growth_method_guide()` creates a design-aware shortlist from the declared objective and sampling structure. `growth_workflow()` can freeze a planning-only contract or execute one explicit core analysis while retaining validation, decisions, diagnostics, traits, comparisons, uncertainty objects, and reproducibility metadata.

```r
maize <- growth_example_data("maize_destructive")
gm <- growth_data(
  maize, time = "day", sampling = "destructive",
  experimental_unit = "plot_id", treatment = "nitrogen",
  total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
  leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2"
)

plan <- growth_workflow(
  gm,
  objective = "trajectory",
  execute = FALSE,
  seed = 20260827
)

growth_workflow_audit(plan)
growth_report(plan)
```

For executed analyses, use an explicit strategy when the scientific method has already been decided. Automatic mode is intentionally conservative and is not a substitute for experimental or biological judgment.

```r
sun <- growth_example_data("sunflower_sigmoid")
sun1 <- subset(sun, cultivar == unique(sun$cultivar)[1])

wf <- growth_workflow(
  sun1,
  time = "day",
  response = "biomass_g",
  strategy = "parametric",
  models = c("logistic", "gompertz", "richards"),
  n_start = 10,
  seed = 20260827
)

growth_table(wf, "traits")
growth_export(wf, "analysis_bundle", format = "bundle")
```

## Biological events and agronomic decisions

Version 0.5.0 adds explicit tools for growth processes that are not well represented by a single uninterrupted sigmoid. The new layer covers ordered multiphase trajectories, measured biomass-loss events, compensatory growth, plant density and neighborhood competition, critical biological thresholds, observation planning, and conditional harvest decisions.

```r
coffee <- growth_example_data("coffee_diphasic")
mp <- growth_diphasic(
  coffee, time = "day", response = "biomass_g",
  group = "treatment", n_start = 10, seed = 20260827
)
mp

bean <- growth_example_data("bean_defoliation")
def <- growth_defoliation(
  subset(bean, treatment == "defoliated"),
  time = "day", total_mass = "total_mass_g",
  leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2",
  total_loss = "total_loss_g", leaf_mass_loss = "leaf_mass_loss_g",
  leaf_area_loss = "leaf_area_loss_m2", unit = "plant_id"
)
def
```

`growth_stability()` evaluates the fourth derivative of the complete fitted curve. `growth_changepoint()` offers an exploratory one-breakpoint continuous piecewise-linear analysis. These two tools answer different questions and should not be used as interchangeable evidence for biological phases.

For decision support, `growth_threshold()` and `growth_plateau_time()` convert a fitted trajectory into explicit biological times. `growth_harvest_opt()` then allows the user to add economic assumptions, but the result remains conditional on those assumptions and the selected growth model. `growth_schedule()` distributes planned observations equally or uses a transparent rate-and-curvature heuristic; it does not claim statistical optimality.

The new competition tools also keep their scope explicit. `growth_neighbor()` computes a readable size-distance neighborhood index, while `growth_competition()` integrates a generic coupled logistic system with RK4. Neither function is presented as an implementation of the exact spatial zone-of-influence equations in Gates (1982).

## Design-aware bootstrap uncertainty

```r
sun <- growth_example_data("sunflower_sigmoid")
sun1 <- subset(sun, cultivar == unique(sun$cultivar)[1])
fit <- growth_fit(sun1, "logistic", time = "day", response = "biomass_g")

b <- growth_boot(fit, R = 999, method = "case", seed = 123)
growth_boot_ci(b, source = "coefficients")
growth_boot_traits(b, traits = c("t50", "t90", "maximum_absolute_rate"))
```

The resampling methods are `case`, `cluster`, `residual`, `parametric`, `wild`, and `cluster_wild`, plus `auto`. Cluster methods resample persistent unit trajectories rather than isolated rows. Every nonlinear refit is audited, and a low success rate is reported rather than hidden. Model-family sensitivity can be examined independently with `growth_selection_stability()`.

## Bayesian nonlinear growth

Version 0.4.0 provides an optional `brms` interface for Logistic, Gompertz, and Richards growth curves. Positive biological parameters are modeled on transformed scales, and treatment or persistent-unit effects can enter nonlinear parameters hierarchically. Other parametric families remain available through the frequentist layer and are intentionally refused by the Bayesian convenience API until their prior and hierarchical parameterizations are validated.

```r
p <- growth_prior(sun1, "logistic", time = "day", response = "biomass_g")
p

if (requireNamespace("brms", quietly = TRUE)) {
  # Example only. Increase iterations after checking the real analysis design.
  # bfit <- growth_bayes(
  #   sun1, "logistic", time = "day", response = "biomass_g",
  #   chains = 4, iter = 2000, warmup = 1000, seed = 456
  # )
  # growth_bayes_diagnose(bfit)
  # growth_pp_check(bfit)
  # growth_posterior_traits(bfit)
}
```

The Bayesian workflow includes prior-only fitting, posterior predictive checks, rank-normalized R-hat and effective sample-size diagnostics, divergent-transition counts, PSIS-LOO with Pareto-k diagnostics, and LOO-based stacking or pseudo-BMA predictive weighting. Bayesian packages remain optional dependencies.

## Longitudinal mixed-effects growth

```r
library(agriGrowthFlow)

bean <- growth_example_data("bean_repeated")

g <- growth_data(
  bean,
  time = "day",
  sampling = "repeated",
  experimental_unit = "plant_id",
  plant = "plant_id",
  block = "block",
  treatment = "water_regime",
  leaf_area = "projected_leaf_area_m2"
)

if (requireNamespace("nlme", quietly = TRUE)) {
  m <- growth_mixed(
    g,
    response = "height_cm",
    degree = 2,
    random_degree = 1,
    correlation = "car1",
    variance = "group"
  )
  print(m)
  growth_mixed_diagnose(m)
}
```

`growth_mixed()` uses `nlme::lme()` as an optional established engine. For declared `agri_growth_data`, treatment and block roles are used automatically unless the user supplies explicit alternatives. Continuous-time AR(1) correlation is available through `corCAR1`; integer-time AR(1) is available through `corAR1`; variance functions include power, exponential, group-specific and time-specific residual scales.

## Flexible smoothing and derivatives

```r
s <- growth_smooth(
  bean,
  time = "day",
  response = "projected_leaf_area_m2",
  group = "water_regime",
  method = "smooth_spline"
)

growth_smooth_predict(s)
growth_derivative(s, order = 1)
growth_acceleration(s)
growth_smooth_traits(s)
```

The default flexible engines are available in base R: smoothing splines and LOESS. Optional `mgcv` and `scam` engines add GAM and shape-constrained additive trajectories. The package does not impose monotonicity automatically because plant area, pigment traits and biomass may plateau or decline during senescence or stress.

## Functional growth and FPCA

```r
fp <- growth_fpca(
  bean,
  time = "day",
  response = "height_cm",
  unit = "plant_id",
  group = "water_regime",
  engine = "grid",
  pve = 0.95
)

fp$scores_table
fp$eigenfunctions
```

The built-in `grid` engine reconstructs each unit only on the common observed support and performs an L2-scaled discretized FPCA. Optional `fdapace` and `refund` engines support sparse or irregular functional-data workflows without making those packages mandatory dependencies.

## Multivariate growth components

```r
maize <- growth_example_data("maize_destructive")

coef_tab <- growth_curve_coefficients(
  maize,
  time = "day",
  response = "total_mass_g",
  unit = "plot_id",
  group = "nitrogen",
  degree = 2
)

mv <- growth_manova(
  maize,
  time = "day",
  response = "total_mass_g",
  unit = "plot_id",
  group = "nitrogen",
  degree = 2,
  test = "Pillai"
)
```

This module follows the design logic of coefficient-based growth-curve analysis: destructive subsamples are first reduced to the persistent plot by harvest-time level, each plot is represented by orthogonal polynomial curve components, and treatment differences are evaluated multivariately. Missing harvest times are not silently interpolated for this analysis.

## Parametric and classical layers remain available

```r
sun <- growth_example_data("sunflower_sigmoid")
fit <- growth_fit(sun, c("logistic", "gompertz"), time = "day", response = "biomass_g",
                  group = "cultivar", n_start = 10, seed = 20260827)
growth_traits(fit)

gm <- growth_data(
  maize,
  time = "day",
  sampling = "destructive",
  experimental_unit = "plot_id",
  treatment = "nitrogen",
  block = "block",
  total_mass = "total_mass_g",
  leaf_area = "leaf_area_m2",
  leaf_mass = "leaf_mass_g",
  root_mass = "root_mass_g",
  stem_mass = "stem_mass_g",
  reproductive_mass = "reproductive_mass_g",
  ground_area = "ground_area_m2"
)
growth_indices(gm)
```

## Documentation

Version 1.0.0 contains 31 extensive English vignettes. The complete sequence runs from `v00` through `v30`. The release-specific additions are:

- `v28-release-workflow-contract.Rmd`
- `v29-reporting-audit-export.Rmd`
- `v30-foundations-to-release-tutorial.Rmd`

The earlier tutorials remain part of the package so foundations, parametric models, longitudinal and flexible analysis, functional data analysis, uncertainty, biological events, competition, and decision support can be studied independently before using the integrated release workflow.

Cheatsheets (PT-BR and EN) with reproducible workflows are available in `cheatsheet/` as Quarto source and rendered HTML, outside the CRAN tarball:

- `cheatsheet/agriGrowthFlow-cheatsheet-PT.qmd` + `.html`
- `cheatsheet/agriGrowthFlow-cheatsheet-EN.qmd` + `.html` (also as vignette `v30`)

## Reference audit

Scientific references are recorded in `vignettes/references.bib`. Two-source metadata verification is stored in `inst/metadata/reference_verification.csv` and consolidated for the stable release in `REFERENCE_AUDIT_1.0.0.md`. No new statistical method was introduced only for the release orchestration layer, so the 25 verified scientific references from versions 0.1.0 to 0.5.0 remain the scientific basis of 1.0.0.



## Validation status

The source tree contains unit tests, numerical known-truth controls and a static validation battery. The current build environment does not contain R. The frozen 1.0.0 source snapshot is statically validated and archive-verified, while runtime release validation still requires local roxygen regeneration, test execution, vignette rendering, `R CMD build`, and `R CMD check --as-cran`.


## Version 0.4.0 uncertainty layer

Version 0.4.0 adds design-aware bootstrap resampling, nonlinear bootstrap confidence intervals, model-selection stability, Bayesian nonlinear hierarchical Logistic/Gompertz/Richards models, scaled prior templates, prior and posterior predictive checks, posterior growth-trait uncertainty, modern MCMC diagnostics, PSIS-LOO, and stacking or pseudo-BMA+ predictive weighting. Bayesian computation is optional and uses brms/Stan only when requested.

The uncertainty layer preserves the persistent experimental unit and refuses LOO-based weighting when candidate Bayesian models were not fitted to identical prepared observations.
