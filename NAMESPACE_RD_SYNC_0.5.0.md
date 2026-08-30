# agriGrowthFlow 0.5.0 NAMESPACE and Rd Synchronization Audit

## Static synchronization result

- Exported public functions: **69**
- Registered S3 methods: **38**
- R source files: **21**
- Rd manual files: **23**
- Exported functions without source definition: **0**
- Exported functions without Rd alias: **0**
- Exported functions with duplicate Rd aliases: **0**
- Registered S3 methods without source definition: **0**

All source-level synchronization checks passed.

## Version 0.5.0 API mapping

- `growth_multiphase()` -> `multiphase_events.Rd`
- `growth_diphasic()` -> `multiphase_events.Rd`
- `growth_stability()` -> `multiphase_events.Rd`
- `growth_changepoint()` -> `multiphase_events.Rd`
- `growth_event()` -> `disturbance_growth.Rd`
- `growth_defoliation()` -> `disturbance_growth.Rd`
- `growth_compensation()` -> `disturbance_growth.Rd`
- `growth_density()` -> `competition_growth.Rd`
- `growth_neighbor()` -> `competition_growth.Rd`
- `growth_competition()` -> `competition_growth.Rd`
- `growth_threshold()` -> `growth_decision_design.Rd`
- `growth_plateau_time()` -> `growth_decision_design.Rd`
- `growth_harvest_opt()` -> `growth_decision_design.Rd`
- `growth_schedule()` -> `growth_decision_design.Rd`
- `growth_design_sim()` -> `growth_decision_design.Rd`
- `growth_power()` -> `growth_decision_design.Rd`

## Interpretation

This report verifies the distributed source tree: every NAMESPACE export has a function definition and one unique Rd alias, and every registered S3 method has a source definition. The package contains manually synchronized Rd files because R and roxygen2 are not installed in this environment.

Local validation must still run `roxygen2::roxygenise()` and inspect the resulting NAMESPACE and Rd diff. Any unexpected generated change is a release blocker until reviewed.

## Export list

- `growth_agr`
- `growth_allometry`
- `growth_cgr`
- `growth_classical`
- `growth_data`
- `growth_design`
- `growth_example_data`
- `growth_indices`
- `growth_lad`
- `growth_lai`
- `growth_lar`
- `growth_lmr`
- `growth_nar`
- `growth_partition`
- `growth_plan`
- `growth_plot`
- `growth_rgr`
- `growth_sla`
- `growth_validate`
- `growth_models`
- `growth_start`
- `growth_fit`
- `growth_multistart`
- `growth_predict`
- `growth_compare`
- `growth_diagnose`
- `growth_traits`
- `growth_inflection`
- `growth_maxrate`
- `growth_time_to`
- `growth_mixed`
- `growth_mixed_diagnose`
- `growth_smooth`
- `growth_smooth_predict`
- `growth_derivative`
- `growth_acceleration`
- `growth_smooth_traits`
- `growth_fpca`
- `growth_functional`
- `growth_curve_coefficients`
- `growth_manova`
- `growth_boot`
- `growth_boot_ci`
- `growth_boot_traits`
- `growth_selection_stability`
- `growth_prior`
- `growth_bayes`
- `growth_prior_predict`
- `growth_pp_check`
- `growth_bayes_diagnose`
- `growth_posterior_traits`
- `growth_loo`
- `growth_model_average`
- `growth_multiphase`
- `growth_diphasic`
- `growth_stability`
- `growth_changepoint`
- `growth_event`
- `growth_defoliation`
- `growth_compensation`
- `growth_density`
- `growth_neighbor`
- `growth_competition`
- `growth_threshold`
- `growth_plateau_time`
- `growth_harvest_opt`
- `growth_schedule`
- `growth_design_sim`
- `growth_power`
