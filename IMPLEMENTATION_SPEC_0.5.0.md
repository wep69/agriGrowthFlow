# agriGrowthFlow 0.5.0 Implementation Specification

## Release objective

Version 0.5.0 adds the Biological Events and Agronomic Decisions layer while preserving the APIs of versions 0.1.0 through 0.4.0. The public API now contains 69 exported functions.

The new layer is organized around four scientific problems:

1. multiphase growth and structural transitions;
2. disturbances, defoliation, and compensation;
3. density and spatial competition;
4. biological thresholds, observation planning, harvest decisions, design simulation, and power.

## New public functions

### 1. `growth_multiphase()`

**Purpose:** fit one to three ordered logistic growth phases.

**Key arguments:** `x`, `time`, `response`, `n_phases`, `group`, `start`, `n_start`, `seed`, `aggregate`, `control`.

**Input:** data frame or `agri_growth_data`.

**Output:** `agri_growth_multiphase` or `agri_growth_multiphase_collection`.

**Validation:** phase count restricted to 1-3; positive amplitude and scale are enforced by log transformation; later phase centers are defined by positive exponential gaps; multistart attempts are retained.

### 2. `growth_diphasic()`

Readable wrapper around `growth_multiphase(..., n_phases = 2)`.

### 3. `growth_stability()`

**Purpose:** locate zeros of the fourth derivative on the complete fitted curve.

**Input:** supported parametric, multiphase, or smooth growth object.

**Output:** data frame with stability time and fitted response.

**Validation:** finite increasing search interval; numerical search uses the complete summed trajectory.

### 4. `growth_changepoint()`

**Purpose:** exploratory one-breakpoint continuous piecewise-linear regression.

**Model:** `y = beta0 + beta1*time + beta2*max(time-c,0) + error`.

**Output:** `agri_growth_changepoint` with candidate table, selected breakpoint, pre-break slope, and post-break slope.

**Limit:** one breakpoint in 0.5.0. It is not a replacement for the `segmented` package.

### 5. `growth_event()`

**Purpose:** declare a known event time and create event-centered variables without estimating the event from the response.

**Output:** `agri_growth_event`.

### 6. `growth_defoliation()`

**Purpose:** iterative plant-growth reconstruction in the presence of measured biomass and leaf-area losses.

**State variables:** total plant mass, leaf lamina mass, leaf area.

**Estimated parameters:** constant NAR, leaf allocation fraction `flam`, and new-leaf SLA multiplier `gamma` over the analyzed window.

**Output:** `agri_growth_defoliation`, with unit-specific parameters, observed states, simulated states, objective value, and convergence code.

**Safeguard:** observed loss columns are inputs. The function does not infer removed tissue from a fitted smooth curve.

### 7. `growth_compensation()`

**Purpose:** compare disturbed treatments with a control using final response, AUC, or slope.

**Output:** group-level summary with compensation ratio and difference from control.

### 8. `growth_density()`

**Purpose:** fit the reciprocal individual-size density relation `1/W = a + bD`.

**Output:** `agri_growth_density` containing the linear model and original variables.

### 9. `growth_neighbor()`

**Purpose:** compute a transparent neighborhood competition index based on neighbor-to-focal size ratio and distance.

**Definition:** `sum((S_j/S_i)^q / d_ij^p)` inside the selected radius.

**Output:** one row per focal plant with index and neighbor count.

### 10. `growth_competition()`

**Purpose:** simulate generic coupled logistic competition.

**Equation:** `dW_i/dt = r_i W_i [1 - (W_i + sum_j alpha_ij W_j)/K_i]`.

**Integrator:** fixed maximum-step fourth-order Runge-Kutta.

**Output:** `agri_growth_competition` with long trajectory and simulation inputs.

**Safeguard:** not described as the exact Gates (1982) zone-of-influence model.

### 11. `growth_threshold()`

**Purpose:** locate absolute or fractional response crossings on supported fitted trajectories.

**Safeguard:** fractional thresholds require a finite upper level.

### 12. `growth_plateau_time()`

**Purpose:** operational plateau time.

**Criteria:** response fraction or post-maximum-rate derivative fraction.

**Defaults:** 95% of finite upper response or 5% of maximum absolute rate.

### 13. `growth_harvest_opt()`

**Purpose:** maximize a conditional net-value curve over a supplied time interval.

**Objective:** value of predicted response after discount minus linear time cost and fixed harvest cost.

**Output:** `agri_growth_harvest` with optimum and full decision curve.

**Safeguard:** result is conditional on model and economic inputs, not an automatic agronomic recommendation.

### 14. `growth_schedule()`

**Purpose:** propose equal or rate-curvature-weighted observation times.

**Safeguard:** explicitly documented as a heuristic rather than statistically optimal design.

### 15. `growth_design_sim()`

**Purpose:** simulate long-format data from the built-in parametric growth equations for pilot design exploration.

**Features:** residual error, optional log-scale between-unit upper-level variation, and simple treatment multipliers.

### 16. `growth_power()`

**Purpose:** Monte Carlo power for a treatment contrast in a derived growth trait when the pilot trait SD is available.

**Output:** `agri_growth_power` with estimated power and Monte Carlo standard error.

**Safeguard:** not presented as power for a complete nonlinear mixed or Bayesian model.

## New S3 methods

Nine print methods are registered for multiphase fits and collections, changepoints, events, defoliation analyses, density models, competition simulations, harvest decisions, and power results.

## New frozen teaching datasets

All are simulated and are explicitly documented as teaching data rather than empirical evidence.

- `coffee_diphasic.csv`: 208 rows, repeated diphasic biomass trajectories under control and stress.
- `bean_defoliation.csv`: 216 rows, total mass, leaf mass, leaf area, and measured loss columns for control and repeated defoliation.
- `maize_density.csv`: 32 rows, individual mass across four densities and two nitrogen regimes.
- `tree_competition.csv`: 64 rows, planar coordinates and simulated plant sizes on an 8 by 8 grid.

The complete teaching-data checksum file contains 10 CSV files.

## Documentation

Version 0.5.0 adds five extensive English vignettes:

- `v23-multiphasic-growth-stability.Rmd`
- `v24-disturbance-defoliation-compensation.Rmd`
- `v25-density-spatial-competition.Rmd`
- `v26-design-schedule-harvest-power.Rmd`
- `v27-biological-events-decisions-workflow.Rmd`

The package now contains 28 vignettes. The integrated v27 tutorial connects design, classical physiology, parametric models, longitudinal models, flexible smoothing, uncertainty, biological events, competition, and decision support.

## References

The double-verification ledger contains 25 records. Version 0.5.0 adds audited metadata for Gates (1982), Muggeo (2003), and Panik (2014), and reuses the already audited Anten and Ackerly (2001) and Mischan et al. (2015) references.

## Runtime validation strategy

Static validation can be completed in this environment. R is not installed here, so the following remain mandatory local runtime gates:

1. regenerate documentation with `roxygen2` and confirm no unexpected NAMESPACE or Rd changes;
2. run the complete `testthat` suite;
3. render all 28 vignettes;
4. run optional backend tests for `nlme`, `mgcv`, `scam`, `refund`, `fdapace`, `brms`, `posterior`, and `loo` when installed;
5. run `R CMD build`;
6. run `R CMD check --as-cran` on the exact built tarball;
7. compare final built artifacts with the frozen source manifest.

The `growth_power()` workflow is explicitly a **trait-level Monte Carlo** planning approximation. It should be replaced by full analysis-pipeline simulation when nonlinear fit failure, covariance, missingness, or posterior uncertainty are central to the design question.
