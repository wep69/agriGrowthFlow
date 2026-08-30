# agriGrowthFlow 0.4.0 Implementation Specification

## Release theme

**Uncertainty, resampling, Bayesian nonlinear hierarchy, predictive evaluation, and model-form averaging.**

Version 0.4.0 extends the 0.1.0 Foundations, 0.2.0 Parametric Growth Models, and 0.3.0 Longitudinal/Flexible Growth layers. It does not alter the design-first rule that the persistent experimental unit must be identified before inferential uncertainty is quantified.

## Public API added in 0.4.0

### Bootstrap layer

- `growth_boot()`
- `growth_boot_ci()`
- `growth_boot_traits()`
- `growth_selection_stability()`

### Bayesian nonlinear layer

- `growth_prior()`
- `growth_bayes()`
- `growth_prior_predict()`
- `growth_pp_check()`
- `growth_bayes_diagnose()`
- `growth_posterior_traits()`

### Bayesian predictive evaluation

- `growth_loo()`
- `growth_model_average()`

The full package public API contains 53 exported functions.

## Bootstrap contracts

`growth_boot()` accepts a single fitted `agri_growth_fit`. Supported methods are case, cluster, residual, parametric, wild, and cluster-wild. `auto` selects cluster resampling only when a persistent unit with repeated observations is present; otherwise it selects case resampling. Complete persistent-unit trajectories are resampled as clusters.

Every requested replicate receives a record. Nonlinear refit failures remain visible. A success rate below 80% produces a warning.

`growth_boot_ci()` summarizes coefficient or trait draws using percentile, basic, or normal intervals. `growth_boot_traits()` is the trait-oriented convenience interface.

`growth_selection_stability()` repeats candidate-model fitting and selection under resampling and returns selection frequencies. Frequencies are not described as posterior model probabilities.

## Bayesian parameterization

Version 0.4.0 supports Bayesian Logistic, Gompertz, and Richards curves. Positive asymptote and scale parameters use log-scale nonlinear predictors. Richards shape is also positive through a log-scale predictor. Midpoint remains on the original time scale.

`growth_prior()` returns data-scaled weakly informative templates. These templates are explicitly documented as starting points requiring scientific revision and prior predictive inspection.

`growth_bayes()` optionally uses `brms` and Stan. Treatment/group effects can enter all nonlinear parameters or be overridden with named nonlinear-parameter formulas. Persistent-unit random-effect templates support asymptote, timing, or all nonlinear parameters.

## Predictive checking and diagnostics

`growth_prior_predict()` calls the same model with `sample_prior = "only"`. `growth_pp_check()` delegates predictive checking to the fitted brms model.

`growth_bayes_diagnose()` reports rank-normalized R-hat summaries, bulk ESS, tail ESS, and divergent transitions.

## Posterior biological traits

`growth_posterior_traits()` transforms posterior draws into asymptote, inflection time/response, maximum absolute rate, time of maximum rate, t10, t50, t90, and AUC over observed support. Population-level summaries exclude random effects by default; unit-specific summaries can include fitted random effects explicitly.

## PSIS-LOO and model averaging

`growth_loo()` wraps PSIS-LOO and stores Pareto-k diagnostics. LOO is refused for prior-only fits.

`growth_model_average()` accepts at least two Bayesian growth fits and checks an exact prepared-observation key before computing weights. Supported weighting is stacking or pseudo-BMA, with Bayesian-bootstrap regularization available for pseudo-BMA+. The function can return weights only or Monte Carlo mixtures of posterior expected/predictive draws.

## Optional dependency policy

The Bayesian stack remains optional: `brms`, `posterior`, `loo`, and `cmdstanr` are in Suggests. The package never installs dependencies automatically. Backend availability is checked with `requireNamespace()`.

## Documentation

Version 0.4.0 adds five extensive vignettes: v18 through v22, bringing the package to 23 total vignettes. They cover design-aware bootstrap, bootstrap intervals and model-selection stability, Bayesian nonlinear hierarchy, prior/posterior predictive checking, PSIS-LOO and stacking, and an integrated uncertainty workflow.

## Tests

Static and unit-test sources cover bootstrap method selection, cluster trajectory resampling, interval construction, model-selection frequencies, prior parameter transformations, design-role preservation, Bayesian formula templates, unsupported-family refusal, and an opt-in compiled Bayesian smoke test guarded by `AGRIGROWTHFLOW_RUN_BAYES_TESTS=true`.

## Release gates

1. Static source validation with zero failures.
2. Export/NAMESPACE/manual alias synchronization.
3. Consolidated API examples with at least three calls for all 53 exported functions.
4. Two-source audit for all 22 core references.
5. Local R execution of testthat.
6. Rendering of all vignettes.
7. `R CMD build` and `R CMD check --as-cran` on the exact built tarball.

The last three runtime gates require an R installation and Stan toolchain for the optional Bayesian smoke tests.
