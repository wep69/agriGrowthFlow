# agriGrowthFlow 1.0.0

## Consolidated Release

- Consolidated the complete 0.1.0 to 0.5.0 architecture into a stable 1.0.0 public API.
- Added `growth_method_guide()` for transparent design- and objective-aware method shortlisting.
- Added `growth_workflow()` as an auditable orchestration layer connecting validation, one explicit core analysis, diagnostics, biological traits, candidate comparison, and optional uncertainty.
- Added planning-only workflows through `execute = FALSE` so analysis decisions can be reviewed before model fitting.
- Added `growth_workflow_audit()` with explicit PASS, INFO, and FAIL gates.
- Added `growth_table()` for standardized tabular extraction from common package objects.
- Added `growth_report()` for compact reproducible Markdown analysis records.
- Added `growth_export()` for RDS preservation, CSV table export, and multi-file review bundles.
- Added three extensive English vignettes covering the consolidated workflow contract, reporting/audit/export, and a foundations-to-release tutorial.
- Added a release API contract and signatures ledger for the complete public interface.
- Updated `README`, `NEWS`, `CITATION`, documentation, examples, tests, and static validation for the stable release.

## Release safeguards

- Automatic method guidance is a transparent planning aid, not proof that one method is scientifically correct.
- Automatic mode never selects a final scientific conclusion from a p-value, R-squared, AIC, AICc, or another single statistic.
- The consolidated workflow preserves declared sampling structure and persistent experimental units.
- Grouped candidate model comparisons remain within identical prepared observations.
- Automatic bootstrap is not silently applied across grouped fit collections.
- Bayesian execution remains optional and requires its declared backend and diagnostic workflow.
- Markdown reports summarize the analysis contract without generating unsupported publication claims.
- RDS remains the preferred complete archive because flat files cannot preserve nested model objects.

# agriGrowthFlow 0.5.0

## Biological Events and Agronomic Decisions

- Added `growth_multiphase()` and `growth_diphasic()` for ordered sums of one to three logistic phases.
- Added `growth_stability()` to locate fourth-derivative stability points on the complete fitted trajectory.
- Added `growth_changepoint()` for transparent exploratory continuous piecewise-linear breakpoint searches.
- Added `growth_event()`, `growth_defoliation()`, and `growth_compensation()` for known disturbances, measured biomass and leaf-area losses, and compensatory-growth summaries.
- Added `growth_density()`, `growth_neighbor()`, and `growth_competition()` for reciprocal size-density analysis, transparent size-distance neighborhood indices, and coupled logistic competition simulations.
- Added `growth_threshold()`, `growth_plateau_time()`, and `growth_harvest_opt()` for biologically defined decision points and model-conditioned harvest optimization.
- Added `growth_schedule()`, `growth_design_sim()`, and `growth_power()` for transparent observation-schedule heuristics, simulated growth designs, and Monte Carlo power on derived traits.
- Added four frozen simulated teaching datasets: `coffee_diphasic`, `bean_defoliation`, `maize_density`, and `tree_competition`.
- Added five extensive English vignettes and an integrated biological-events and decisions workflow.
- Expanded the two-source reference audit to 25 records.

## Scientific safeguards

- Multiphase inflection and stability behavior is interpreted from the complete summed trajectory rather than component formulas alone.
- Defoliation analysis requires measured loss inputs when losses occurred; the package does not infer removed biomass from a smooth curve.
- The neighborhood index and coupled logistic simulator are generic transparent models and are not labeled as the exact zone-of-influence equations of Gates.
- `growth_schedule()` is explicitly a heuristic, not a proof of D-optimality.
- `growth_harvest_opt()` is conditional on user-supplied biological and economic assumptions and is not an automatic harvest recommendation.
- `growth_power()` is a trait-level Monte Carlo planning approximation and does not replace simulation of a complete mixed or Bayesian growth model.

# agriGrowthFlow 0.4.0

## Uncertainty: Bootstrap and Bayesian Growth

- Added `growth_boot()` with design-aware case, cluster, residual, parametric, wild, and cluster-wild resampling of parametric growth curves.
- Added `growth_boot_ci()` and `growth_boot_traits()` so nonlinear refitting uncertainty propagates to coefficients and biologically interpretable traits.
- Added `growth_selection_stability()` to repeat candidate-model comparison under case or persistent-unit cluster resampling without privileging one data-generating candidate.
- Added `growth_prior()` with readable, data-scaled prior templates for Bayesian Logistic, Gompertz, and Richards growth models.
- Added `growth_prior_predict()` and `growth_pp_check()` for prior and posterior predictive evaluation.
- Added `growth_bayes()` as an optional `brms` interface with treatment effects and persistent-unit hierarchy on transformed nonlinear parameters.
- Added `growth_bayes_diagnose()` using rank-normalized R-hat, bulk ESS, tail ESS, and divergent-transition counts.
- Added `growth_posterior_traits()` to transform posterior nonlinear parameters into timing, inflection, maximum-rate, and observed-support AUC summaries.
- Added `growth_loo()` with PSIS-LOO and retained Pareto-k diagnostics.
- Added `growth_model_average()` with `loo` stacking or pseudo-BMA weighting and Monte Carlo mixtures of posterior expected or predictive distributions.
- Added five extensive English vignettes on resampling, trait uncertainty, Bayesian nonlinear growth, MCMC/LOO diagnostics, predictive model averaging, and the integrated 0.4.0 workflow.
- Expanded the two-source reference audit to 22 records, including bootstrap, Bayesian multilevel modeling, modern MCMC diagnostics, PSIS-LOO, and stacking.

## Scientific safeguards

- Bootstrap resampling retains complete persistent-unit trajectories when cluster methods are selected.
- Nonlinear bootstrap refit failures are retained in an audit table; low refit success triggers a warning.
- Model-selection stability resamples cases or clusters instead of simulating from one privileged candidate model.
- Bayesian convenience fitting is deliberately limited to Logistic, Gompertz, and Richards until additional families receive validated positive-parameter priors, hierarchy, and posterior-trait mappings.
- Prior-only objects cannot be used for LOO or model averaging.
- Bayesian models must be fitted to identical prepared observations before model averaging is allowed.
- MCMC diagnostics and Pareto-k values remain explicit outputs rather than being converted into hidden automatic decisions.
- Bayesian dependencies remain optional; no package is installed automatically.

# agriGrowthFlow 0.3.0

## Longitudinal and Flexible Growth

- Added `growth_mixed()` using `nlme::lme()` for design-aware polynomial longitudinal growth analysis with persistent-unit random effects.
- Added explicit residual correlation choices for independent, discrete AR(1), and continuous-time AR(1) structures.
- Added residual variance structures for fitted-value power, fitted-value exponential, group-specific, and harvest-time-specific heterogeneity.
- Added `growth_mixed_diagnose()` with normalized residual summaries and within-unit lag diagnostics.
- Added `growth_smooth()` with base-R smoothing spline and LOESS engines plus optional `mgcv` GAM and `scam` monotone trajectory engines.
- Added `growth_smooth_predict()`, `growth_derivative()`, `growth_acceleration()`, and `growth_smooth_traits()` for flexible trajectory interpretation.
- Added `growth_fpca()` and `growth_functional()` with a built-in common-support L2-scaled grid FPCA and optional `fdapace` and `refund` engines for irregular or sparse functional growth data.
- Added `growth_curve_coefficients()` and `growth_manova()` for experimental-unit orthogonal polynomial decomposition and MANOVA of growth components on a common observed time grid.
- Added a frozen simulated irregular soybean imaging dataset for sparse functional-growth examples.
- Added six extensive English vignettes for longitudinal mixed models, flexible smoothing, shape constraints, FPCA, MANOVA, and an integrated 0.3.0 workflow.
- Expanded the two-source reference audit for mixed-effects, growth-curve analysis, shape-constrained smoothing, and functional data analysis.
- Preserved the 0.2.0 frozen snapshots as immutable artifacts and retained all earlier APIs.

## Scientific safeguards

- Destructive subsamples are aggregated within persistent experimental unit and harvest time before longitudinal modeling when the sampling structure is declared.
- `corAR1` is restricted to integer-valued time; irregular continuous time is directed to `corCAR1`.
- Monotone SCAM constraints are opt-in and are not imposed when senescence or stress may create declining trajectories.
- Grid FPCA uses only the common observed support and refuses to extrapolate units onto non-overlapping time domains.
- MANOVA growth-component analysis requires the same observed time grid for every persistent unit and does not silently impute missing harvests.
- Flexible smoothing is described as trajectory estimation; it is not presented as a substitute for hierarchical longitudinal inference.

# agriGrowthFlow 0.2.0

## Parametric Growth Models

- Added `growth_models()` with eight built-in plant-growth equations: logistic,
  Gompertz, Richards, Chapman-Richards, Weibull, von Bertalanffy, beta growth and
  expolinear.
- Added `growth_start()` to expose deterministic automatic starting values and
  internal hard/search bounds before optimization.
- Added `growth_fit()` for bounded nonlinear least squares and `growth_multistart()`
  for explicit repeated initialization with preserved fitting-attempt records.
- Added optional `minpack.lm::nlsLM()` support while retaining base R `nls()` as a
  complete default engine.
- Added design-aware destructive aggregation at persistent experimental-unit by
  harvest-time level before curve fitting when an `agri_growth_data` object is used.
- Added explicit cautions when ordinary nonlinear least squares is applied to data
  with repeated or serial experimental-unit dependence.
- Added `growth_compare()` for same-observation AIC/AICc/BIC, RSS, RMSE, MAE,
  delta-AICc and Akaike-weight summaries.
- Added `growth_predict()` with fitted trajectories plus local delta-method confidence
  and prediction intervals.
- Added `growth_diagnose()` with residual error summaries, unit-aware lag diagnostics,
  covariance conditioning, boundary flags and multistart-attempt audit.
- Added `growth_traits()`, `growth_inflection()`, `growth_maxrate()` and
  `growth_time_to()` for biologically interpretable curve landmarks.
- Implemented the corrected Yin et al. beta-growth exponent documented in the 2003
  erratum.
- Added simulated sunflower sigmoid and wheat expolinear teaching datasets.
- Added five extensive English vignettes for the parametric layer, including a long
  integrated foundations-to-parametric tutorial.
- Expanded scientific-reference verification with two-source checks for the new core
  nonlinear-growth literature.

## Foundation maintenance carried into 0.2.0

- Classical vectorized growth functions now reject ambiguous R vector recycling.
- Added an explicit print method for biomass-partition objects.
- Preserved the immutable 0.1.0 source snapshots and documented unresolved local-R
  validation as a release gate rather than silently marking it complete.

# agriGrowthFlow 0.1.0

## Foundations

- Introduced `growth_data()` for explicit role mapping of time, experimental unit,
  sampling scheme, treatment structure, biomass, leaf area and component masses.
- Added `growth_design()`, `growth_validate()` and `growth_plan()` to protect the
  experimental design before calculating derived growth quantities.
- Added `growth_plot()` for raw and summarized trajectory visualization.
- Added classical growth quantities: AGR, RGR, NAR, LAR, SLA, LMR, CGR, LAI and LAD.
- Added `growth_classical()` / `growth_indices()` for design-aware interval analysis.
- Added `growth_partition()` for biomass allocation and closure checks.
- Added `growth_allometry()` for log-log allometric analysis with confidence intervals.
- Added three frozen simulated teaching datasets in `inst/extdata`.
- Added seven extensive English vignettes, including an integrated foundations-to-advanced tutorial.
- Added metadata verification records for the scientific references used in the documentation.
