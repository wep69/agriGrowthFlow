# agriGrowthFlow 0.2.0 Implementation Specification

## Release objective

Extend the design-aware 0.1.0 foundation with a parametric plant-growth layer that provides biologically interpretable nonlinear trajectories without treating ordinary nonlinear least squares as a substitute for longitudinal mixed-effects inference.

## Public API added in 0.2.0

| Function | Main responsibility | Principal output |
|---|---|---|
| `growth_models()` | inspect built-in equation registry | data frame |
| `growth_start()` | expose automatic starts and bounds | `agri_growth_start` |
| `growth_fit()` | fit one model, candidate models, or grouped descriptive curves | `agri_growth_fit` / set / collection |
| `growth_multistart()` | explicit repeated initialization | same fit classes |
| `growth_predict()` | fitted trajectory and local delta-method intervals | data frame |
| `growth_compare()` | same-observation model comparison | `agri_growth_comparison` |
| `growth_diagnose()` | convergence/residual/boundary/conditioning summaries | `agri_growth_diagnostics` |
| `growth_traits()` | common biological curve landmarks | data frame |
| `growth_inflection()` | inflection point extraction | data frame |
| `growth_maxrate()` | maximum absolute growth rate | data frame |
| `growth_time_to()` | time to fractional or absolute target | data frame |

## Built-in equations

1. Logistic: `asym`, `mid`, `scale`.
2. Gompertz: `asym`, `mid`, `scale`.
3. Richards: `asym`, `mid`, `scale`, `shape`.
4. Chapman-Richards: `asym`, `rate`, `shape`, `origin`.
5. Weibull cumulative growth: `asym`, `scale`, `shape`, `origin`.
6. von Bertalanffy cubic form: `asym`, `rate`, `origin`.
7. Beta growth: public `wmax`, `tm`, `te`; internal `gap = te - tm`.
8. Expolinear: `cm`, `rm`, `tb`.

## Core safeguards

- Built-in response values must be non-negative.
- Parametric fitting requires at least four complete observations at distinct times.
- Automatic beta-growth fitting requires non-negative elapsed time.
- Named starting values are mandatory when user-supplied.
- Starting values must lie strictly inside hard bounds.
- Multistart failures remain in the attempts table.
- Destructive `agri_growth_data` are aggregated within persistent unit and harvest time under `aggregate = "auto"`.
- Treatment pooling raises a warning when a treatment role exists and `group` is omitted.
- Ordinary NLS on repeated or serial unit data raises a limitation warning.
- `growth_compare()` refuses different prepared observations.
- Unit-aware lag diagnostics do not connect unrelated experimental units.
- Fractional asymptote targets are not fabricated for expolinear growth.
- Beta growth uses the published corrected exponent.

## Numerical engines

### Base engine

`stats::nls(..., algorithm = "port")` with explicit bounds.

### Optional engine

`minpack.lm::nlsLM()` when requested or selected by `engine = "auto"` and installed.

No optional dependency is installed automatically.

## Model comparison

`growth_compare()` returns RSS, RMSE, MAE, AIC, AICc, BIC, delta AICc and Akaike weights. AICc is calculated only when sample size exceeds parameter count plus one. If no model has finite AICc, weights remain unavailable and a warning is returned.

## Prediction

`growth_predict()` returns point predictions. Confidence and prediction intervals use a numerical coefficient gradient and delta-method covariance propagation. Prediction intervals add residual variance. The function does not label these as bootstrap or hierarchical intervals.

## Derived traits

The common trait table contains:

- asymptote or determinate maximum where defined;
- inflection time and response where finite;
- maximum absolute rate;
- time of maximum rate;
- t10, t50 and t90 for finite-upper-level models;
- AUC integrated only over observed time support.

## Testing requirements

- canonical logistic midpoint equals half asymptote;
- Gompertz inflection response equals `A/e`;
- Richards with shape 1 equals logistic under package parameterizations;
- corrected beta growth satisfies `W(0)=0` and `W(te)=wmax`;
- expolinear late finite-difference slope approaches `cm`;
- known noiseless logistic data recover their generating coefficients;
- candidate comparison returns normalized Akaike weights when finite;
- grouped fits return one fit per group;
- destructive subsamples aggregate by stable plot and time;
- confidence and prediction outputs have coherent interval ordering;
- classical 0.1.0 functions reject ambiguous vector recycling.

## Documentation requirements

- retain the seven foundation vignettes;
- add five detailed parametric vignettes;
- provide a long integrated 0.2.0 tutorial;
- include at least three usage patterns per exported function in the distributed API examples file;
- verify all new core scientific-reference metadata against two sources;
- distribute a local validation guide that distinguishes static checks from actual R execution.

## Deferred capabilities

The following are explicitly outside 0.2.0:

- nonlinear mixed effects;
- explicit residual covariance structures;
- GAM/spline derivatives;
- bootstrap uncertainty for nonlinear derived traits;
- Bayesian hierarchical growth models;
- multiphasic sums or segmented nonlinear growth;
- event/discontinuity models for defoliation.

These are deferred rather than approximated with ordinary NLS.
