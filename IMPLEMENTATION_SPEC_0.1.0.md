# agriGrowthFlow 0.1.0: Foundations Implementation Specification

## Scope

Version 0.1.0 implements the design-aware foundation required before nonlinear, smooth, mixed, bootstrap or Bayesian growth modelling is introduced.

## Public API

| Function | Primary role | Main output |
|---|---|---|
| `growth_data()` | Declare time, sampling, design and biological measurement roles | `agri_growth_data` |
| `growth_design()` | Declare CRD/RCBD/repeated/serial-destructive structure | `agri_growth_design` |
| `growth_validate()` | Detect structural conflicts and unsupported growth calculations | `agri_growth_validation` |
| `growth_plan()` | Translate the declared data structure into a conservative analysis plan | `agri_growth_plan` |
| `growth_plot()` | Raw/mean-SE trajectory inspection | `ggplot` |
| `growth_agr()` | Absolute growth rate | numeric |
| `growth_rgr()` | Relative growth rate | numeric |
| `growth_nar()` | Classical interval net assimilation rate | numeric |
| `growth_lar()` | Leaf area ratio | numeric |
| `growth_sla()` | Specific leaf area | numeric |
| `growth_lmr()` | Leaf mass ratio | numeric |
| `growth_cgr()` | Crop growth rate | numeric |
| `growth_lai()` | Leaf area index | numeric |
| `growth_lad()` | Trapezoidal leaf area duration | numeric/data.frame |
| `growth_classical()` / `growth_indices()` | Aggregate within stable unit × harvest and derive interval indices | `agri_growth_indices` |
| `growth_partition()` | Biomass allocation fractions with closure diagnostics | data.frame |
| `growth_allometry()` | Log-log OLS allometry | `agri_growth_allometry` |
| `growth_example_data()` | Load frozen simulated teaching data | data.frame |

## Design rules implemented

1. Time is explicit and must support at least one valid interval.
2. Repeated sampling requires a stable plant/subject or experimental unit.
3. Destructive sampling is expected to preserve a higher-level experimental unit across harvests.
4. Treatment and block should not silently change within a stable experimental unit unless the analyst has a genuinely time-varying design.
5. Serial destructive subsamples are averaged within stable unit × time before consecutive growth intervals are calculated.
6. Four harvest times per biological phase are treated as a useful design target rather than a universal hard rule, following the design discussion of Keuls & Garretsen (1982).
7. RGR, NAR and log-log allometry require positive quantities where logarithms occur.
8. Biomass fractions are not renormalized by default; closure and unallocated mass remain visible.

## Formula layer

### AGR

`AGR = (W2 - W1) / (t2 - t1)`

### RGR

`RGR = [ln(W2) - ln(W1)] / (t2 - t1)`

### NAR

`NAR = [(W2 - W1)/(t2 - t1)] * [ln(A2) - ln(A1)]/(A2 - A1)`

For numerically equal leaf areas, the continuous limit `AGR / A` is used.

### Morphological ratios

- `LAR = leaf_area / total_mass`
- `SLA = leaf_area / leaf_mass`
- `LMR = leaf_mass / total_mass`
- identity check: `LAR = SLA * LMR`

### Stand quantities

- `LAI = leaf_area / ground_area`
- `CGR = AGR / ground_area`
- interval `LAD = ((LAI1 + LAI2)/2) * dt`

### Allometry

`log(y) = log(a) + k log(x)`, fitted by OLS in 0.1.0. The implementation explicitly states that this is directional and not equivalent to standardized major-axis regression.

## Teaching data

All datasets under `inst/extdata` are frozen simulations generated for documentation and unit testing. They are labelled as simulated throughout the vignettes and must not be cited as field evidence.

- `maize_destructive.csv`: RCBD-like serial destructive quadrat sampling.
- `bean_repeated.csv`: non-destructive plant-level repeated phenotyping.
- `soybean_partition.csv`: destructive biomass allocation and allometry.

## Documentation standard

Seven English vignettes are included. The integrated tutorial `v06-foundations-to-advanced-tutorial.Rmd` is intentionally extensive and follows the project standard of progressing from concepts to code, interpretation, errors to avoid, and complete workflows.

## Deferred to later versions

Version 0.1.0 does not implement nonlinear parametric curves, smooth derivatives, nonlinear mixed models, design-preserving bootstrap, Bayesian inference, multiphasic models, known defoliation events, competition models or harvest optimization. These are deferred so that later statistical sophistication is built on an explicit design foundation.
