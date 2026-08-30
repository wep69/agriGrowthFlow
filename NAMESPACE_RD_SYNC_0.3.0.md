# agriGrowthFlow 0.3.0: NAMESPACE / Rd Synchronization Audit

**Audit date:** 2026-08-27

## Summary

- Exported public functions in `NAMESPACE`: **41**.
- Registered S3 methods in `NAMESPACE`: **22**.
- R source files inspected: **18**.
- Manual `.Rd` files inspected: **16**.
- Missing exported function definitions: **0**.
- Missing manual aliases for exported functions: **0**.
- Duplicate manual aliases among exported functions: **0**.
- Registered S3 methods without definitions: **0**.

The stale `growth_smooth()` manual signature detected during the 0.3.0 freeze review was corrected. Its `.Rd` usage now includes `unit = NULL`, matching the public R function signature.

## Export-to-manual map

| Export | Manual |
|---|---|
| `growth_agr` | `classical_growth_rates.Rd` |
| `growth_allometry` | `growth_allometry.Rd` |
| `growth_cgr` | `classical_growth_rates.Rd` |
| `growth_classical` | `growth_classical.Rd` |
| `growth_data` | `growth_data.Rd` |
| `growth_design` | `growth_design.Rd` |
| `growth_example_data` | `growth_data.Rd` |
| `growth_indices` | `growth_classical.Rd` |
| `growth_lad` | `growth_lad.Rd` |
| `growth_lai` | `classical_growth_rates.Rd` |
| `growth_lar` | `classical_growth_rates.Rd` |
| `growth_lmr` | `classical_growth_rates.Rd` |
| `growth_nar` | `classical_growth_rates.Rd` |
| `growth_partition` | `growth_partition.Rd` |
| `growth_plan` | `growth_design.Rd` |
| `growth_plot` | `growth_plot.Rd` |
| `growth_rgr` | `classical_growth_rates.Rd` |
| `growth_sla` | `classical_growth_rates.Rd` |
| `growth_validate` | `growth_design.Rd` |
| `growth_models` | `growth_models.Rd` |
| `growth_start` | `growth_models.Rd` |
| `growth_fit` | `growth_fit.Rd` |
| `growth_multistart` | `growth_fit.Rd` |
| `growth_predict` | `growth_predict.Rd` |
| `growth_compare` | `growth_predict.Rd` |
| `growth_diagnose` | `growth_predict.Rd` |
| `growth_traits` | `growth_traits.Rd` |
| `growth_inflection` | `growth_traits.Rd` |
| `growth_maxrate` | `growth_traits.Rd` |
| `growth_time_to` | `growth_traits.Rd` |
| `growth_mixed` | `longitudinal_growth.Rd` |
| `growth_mixed_diagnose` | `longitudinal_growth.Rd` |
| `growth_smooth` | `flexible_growth.Rd` |
| `growth_smooth_predict` | `flexible_growth.Rd` |
| `growth_derivative` | `flexible_growth.Rd` |
| `growth_acceleration` | `flexible_growth.Rd` |
| `growth_smooth_traits` | `flexible_growth.Rd` |
| `growth_fpca` | `functional_growth.Rd` |
| `growth_functional` | `functional_growth.Rd` |
| `growth_curve_coefficients` | `growth_manova.Rd` |
| `growth_manova` | `growth_manova.Rd` |

## Registered S3 methods

- `as.data.frame.agri_growth_data`: defined
- `coef.agri_growth_fit`: defined
- `plot.agri_growth_fit`: defined
- `print.agri_growth_allometry`: defined
- `print.agri_growth_comparison`: defined
- `print.agri_growth_data`: defined
- `print.agri_growth_design`: defined
- `print.agri_growth_diagnostics`: defined
- `print.agri_growth_fit`: defined
- `print.agri_growth_fit_collection`: defined
- `print.agri_growth_fit_set`: defined
- `print.agri_growth_indices`: defined
- `print.agri_growth_partition`: defined
- `print.agri_growth_plan`: defined
- `print.agri_growth_start`: defined
- `print.agri_growth_validation`: defined
- `print.agri_growth_mixed`: defined
- `print.agri_growth_mixed_diagnostics`: defined
- `print.agri_growth_smooth`: defined
- `print.agri_growth_smooth_collection`: defined
- `print.agri_growth_fpca`: defined
- `print.agri_growth_manova`: defined

## Outcome

Static synchronization status: **PASS**. Every exported function is defined and has exactly one manual alias, and every registered S3 method has a source definition. Actual roxygen regeneration remains a local R release gate because R is unavailable in the current environment.
