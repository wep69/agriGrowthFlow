# agriGrowthFlow 0.3.0: Final Static Validation

## Status

- Final static validation in the current build environment: **437 PASS, 19 FAIL**.
- The current environment does not contain an R executable. Therefore this report does not claim that `R CMD build`, `R CMD check --as-cran`, roxygen regeneration, testthat execution, or vignette rendering were executed.
- The frozen artifact is a source snapshot. A true R-built release tarball remains contingent on the local R validation commands below.

## Checks performed

The static battery checks 0.3.0 package metadata, the 41-function exported API, S3 registration, R delimiter balance, NAMESPACE/Rd alias synchronization, the corrected `growth_smooth()` manual signature, 18-vignette depth, bibliography resolution, two-source metadata records, six teaching-data schemas and hierarchy, retained mathematical known truths, longitudinal covariance safeguards, equal-unit population smoothing, derivative boundary logic, shape constraints, FPCA support and backend contracts, MANOVA grid safeguards, test-source coverage, consolidated examples, source-tree hygiene, and teaching-data checksums.

## Results

| Status | Check | Detail |
|---|---|---|
| PASS | DESCRIPTION contains Package: agriGrowthFlow |  |
| FAIL | DESCRIPTION contains Version: 0.3.0 |  |
| PASS | DESCRIPTION contains License: MIT + file LICENSE |  |
| PASS | DESCRIPTION contains Depends: R (>= 4.2.0) |  |
| PASS | DESCRIPTION title length suitable for CRAN-style metadata | 62 characters |
| PASS | Optional/recommended dependency declared: minpack.lm |  |
| PASS | Optional/recommended dependency declared: nlme |  |
| PASS | Optional/recommended dependency declared: mgcv |  |
| PASS | Optional/recommended dependency declared: scam |  |
| PASS | Optional/recommended dependency declared: refund |  |
| PASS | Optional/recommended dependency declared: fdapace |  |
| PASS | Optional/recommended dependency declared: knitr |  |
| PASS | Optional/recommended dependency declared: rmarkdown |  |
| PASS | Optional/recommended dependency declared: testthat |  |
| PASS | README identifies version 0.3.0 |  |
| PASS | NEWS begins with version 0.3.0 |  |
| PASS | CITATION identifies version 0.3.0 |  |
| PASS | 0.3.0 reference audit present |  |
| PASS | 0.3.0 implementation specification present |  |
| PASS | 0.3.0 NAMESPACE/Rd synchronization audit present |  |
| PASS | .Rbuildignore covers development artifact: LOCAL_VALIDATION_0\.[123]\.0 |  |
| PASS | .Rbuildignore covers development artifact: IMPLEMENTATION_SPEC_0\.[123]\.0 |  |
| PASS | .Rbuildignore covers development artifact: REFERENCE_AUDIT_0\.[123]\.0 |  |
| PASS | .Rbuildignore covers development artifact: FREEZE_MANIFEST_0\.3\.0 |  |
| PASS | .Rbuildignore covers development artifact: SHA256SUMS_0\.3\.0 |  |
| PASS | .Rbuildignore covers development artifact: TREE_0\.3\.0 |  |
| PASS | Rbuildignore excludes synchronization audit from R-built tarball |  |
| FAIL | Public API export count | 53 exports |
| PASS | No duplicate NAMESPACE exports |  |
| PASS | All 0.3.0 public functions exported |  |
| PASS | Exported function defined: growth_agr |  |
| PASS | Exported function defined: growth_allometry |  |
| PASS | Exported function defined: growth_cgr |  |
| PASS | Exported function defined: growth_classical |  |
| PASS | Exported function defined: growth_data |  |
| PASS | Exported function defined: growth_design |  |
| PASS | Exported function defined: growth_example_data |  |
| PASS | Exported function defined: growth_indices |  |
| PASS | Exported function defined: growth_lad |  |
| PASS | Exported function defined: growth_lai |  |
| PASS | Exported function defined: growth_lar |  |
| PASS | Exported function defined: growth_lmr |  |
| PASS | Exported function defined: growth_nar |  |
| PASS | Exported function defined: growth_partition |  |
| PASS | Exported function defined: growth_plan |  |
| PASS | Exported function defined: growth_plot |  |
| PASS | Exported function defined: growth_rgr |  |
| PASS | Exported function defined: growth_sla |  |
| PASS | Exported function defined: growth_validate |  |
| PASS | Exported function defined: growth_models |  |
| PASS | Exported function defined: growth_start |  |
| PASS | Exported function defined: growth_fit |  |
| PASS | Exported function defined: growth_multistart |  |
| PASS | Exported function defined: growth_predict |  |
| PASS | Exported function defined: growth_compare |  |
| PASS | Exported function defined: growth_diagnose |  |
| PASS | Exported function defined: growth_traits |  |
| PASS | Exported function defined: growth_inflection |  |
| PASS | Exported function defined: growth_maxrate |  |
| PASS | Exported function defined: growth_time_to |  |
| PASS | Exported function defined: growth_mixed |  |
| PASS | Exported function defined: growth_mixed_diagnose |  |
| PASS | Exported function defined: growth_smooth |  |
| PASS | Exported function defined: growth_smooth_predict |  |
| PASS | Exported function defined: growth_derivative |  |
| PASS | Exported function defined: growth_acceleration |  |
| PASS | Exported function defined: growth_smooth_traits |  |
| PASS | Exported function defined: growth_fpca |  |
| PASS | Exported function defined: growth_functional |  |
| PASS | Exported function defined: growth_curve_coefficients |  |
| PASS | Exported function defined: growth_manova |  |
| PASS | Exported function defined: growth_boot |  |
| PASS | Exported function defined: growth_boot_ci |  |
| PASS | Exported function defined: growth_boot_traits |  |
| PASS | Exported function defined: growth_selection_stability |  |
| PASS | Exported function defined: growth_prior |  |
| PASS | Exported function defined: growth_bayes |  |
| PASS | Exported function defined: growth_prior_predict |  |
| PASS | Exported function defined: growth_pp_check |  |
| PASS | Exported function defined: growth_bayes_diagnose |  |
| PASS | Exported function defined: growth_posterior_traits |  |
| PASS | Exported function defined: growth_loo |  |
| PASS | Exported function defined: growth_model_average |  |
| FAIL | S3 registration count | 29 S3 methods |
| PASS | S3 method defined: as.data.frame.agri_growth_data |  |
| PASS | S3 method defined: coef.agri_growth_fit |  |
| PASS | S3 method defined: plot.agri_growth_fit |  |
| PASS | S3 method defined: print.agri_growth_allometry |  |
| PASS | S3 method defined: print.agri_growth_comparison |  |
| PASS | S3 method defined: print.agri_growth_data |  |
| PASS | S3 method defined: print.agri_growth_design |  |
| PASS | S3 method defined: print.agri_growth_diagnostics |  |
| PASS | S3 method defined: print.agri_growth_fit |  |
| PASS | S3 method defined: print.agri_growth_fit_collection |  |
| PASS | S3 method defined: print.agri_growth_fit_set |  |
| PASS | S3 method defined: print.agri_growth_indices |  |
| PASS | S3 method defined: print.agri_growth_partition |  |
| PASS | S3 method defined: print.agri_growth_plan |  |
| PASS | S3 method defined: print.agri_growth_start |  |
| PASS | S3 method defined: print.agri_growth_validation |  |
| PASS | S3 method defined: print.agri_growth_mixed |  |
| PASS | S3 method defined: print.agri_growth_mixed_diagnostics |  |
| PASS | S3 method defined: print.agri_growth_smooth |  |
| PASS | S3 method defined: print.agri_growth_smooth_collection |  |
| PASS | S3 method defined: print.agri_growth_fpca |  |
| PASS | S3 method defined: print.agri_growth_manova |  |
| PASS | S3 method defined: print.agri_growth_boot |  |
| PASS | S3 method defined: print.agri_growth_selection_stability |  |
| PASS | S3 method defined: print.agri_growth_prior |  |
| PASS | S3 method defined: print.agri_growth_bayes |  |
| PASS | S3 method defined: print.agri_growth_bayes_diagnostics |  |
| PASS | S3 method defined: print.agri_growth_loo |  |
| PASS | S3 method defined: print.agri_growth_model_average |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_mixed |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_mixed_diagnostics |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_smooth |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_smooth_collection |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_fpca |  |
| PASS | 0.3.0 S3 print method defined: print.agri_growth_manova |  |
| PASS | R delimiter balance: bayesian-growth.R |  |
| PASS | R delimiter balance: bootstrap-uncertainty.R |  |
| PASS | R delimiter balance: classical-rates.R |  |
| PASS | R delimiter balance: classical-workflow.R |  |
| PASS | R delimiter balance: flexible-prep.R |  |
| PASS | R delimiter balance: functional-growth.R |  |
| PASS | R delimiter balance: growth-data.R |  |
| PASS | R delimiter balance: growth-design.R |  |
| PASS | R delimiter balance: growth-manova.R |  |
| PASS | R delimiter balance: longitudinal-mixed.R |  |
| PASS | R delimiter balance: model-registry.R |  |
| PASS | R delimiter balance: parametric-diagnostics.R |  |
| PASS | R delimiter balance: parametric-fit.R |  |
| PASS | R delimiter balance: parametric-predict-compare.R |  |
| PASS | R delimiter balance: parametric-prep-start.R |  |
| PASS | R delimiter balance: parametric-traits.R |  |
| PASS | R delimiter balance: partition-allometry.R |  |
| PASS | R delimiter balance: plot.R |  |
| PASS | R delimiter balance: smooth-growth.R |  |
| PASS | R delimiter balance: utils.R |  |
| PASS | Manual alias present: growth_agr |  |
| PASS | Manual alias unique: growth_agr | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_allometry |  |
| PASS | Manual alias unique: growth_allometry | growth_allometry.Rd |
| PASS | Manual alias present: growth_cgr |  |
| PASS | Manual alias unique: growth_cgr | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_classical |  |
| PASS | Manual alias unique: growth_classical | growth_classical.Rd |
| PASS | Manual alias present: growth_data |  |
| PASS | Manual alias unique: growth_data | growth_data.Rd |
| PASS | Manual alias present: growth_design |  |
| PASS | Manual alias unique: growth_design | growth_design.Rd |
| PASS | Manual alias present: growth_example_data |  |
| PASS | Manual alias unique: growth_example_data | growth_data.Rd |
| PASS | Manual alias present: growth_indices |  |
| PASS | Manual alias unique: growth_indices | growth_classical.Rd |
| PASS | Manual alias present: growth_lad |  |
| PASS | Manual alias unique: growth_lad | growth_lad.Rd |
| PASS | Manual alias present: growth_lai |  |
| PASS | Manual alias unique: growth_lai | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_lar |  |
| PASS | Manual alias unique: growth_lar | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_lmr |  |
| PASS | Manual alias unique: growth_lmr | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_nar |  |
| PASS | Manual alias unique: growth_nar | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_partition |  |
| PASS | Manual alias unique: growth_partition | growth_partition.Rd |
| PASS | Manual alias present: growth_plan |  |
| PASS | Manual alias unique: growth_plan | growth_design.Rd |
| PASS | Manual alias present: growth_plot |  |
| PASS | Manual alias unique: growth_plot | growth_plot.Rd |
| PASS | Manual alias present: growth_rgr |  |
| PASS | Manual alias unique: growth_rgr | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_sla |  |
| PASS | Manual alias unique: growth_sla | classical_growth_rates.Rd |
| PASS | Manual alias present: growth_validate |  |
| PASS | Manual alias unique: growth_validate | growth_design.Rd |
| PASS | Manual alias present: growth_models |  |
| PASS | Manual alias unique: growth_models | growth_models.Rd |
| PASS | Manual alias present: growth_start |  |
| PASS | Manual alias unique: growth_start | growth_models.Rd |
| PASS | Manual alias present: growth_fit |  |
| PASS | Manual alias unique: growth_fit | growth_fit.Rd |
| PASS | Manual alias present: growth_multistart |  |
| PASS | Manual alias unique: growth_multistart | growth_fit.Rd |
| PASS | Manual alias present: growth_predict |  |
| PASS | Manual alias unique: growth_predict | growth_predict.Rd |
| PASS | Manual alias present: growth_compare |  |
| PASS | Manual alias unique: growth_compare | growth_predict.Rd |
| PASS | Manual alias present: growth_diagnose |  |
| PASS | Manual alias unique: growth_diagnose | growth_predict.Rd |
| PASS | Manual alias present: growth_traits |  |
| PASS | Manual alias unique: growth_traits | growth_traits.Rd |
| PASS | Manual alias present: growth_inflection |  |
| PASS | Manual alias unique: growth_inflection | growth_traits.Rd |
| PASS | Manual alias present: growth_maxrate |  |
| PASS | Manual alias unique: growth_maxrate | growth_traits.Rd |
| PASS | Manual alias present: growth_time_to |  |
| PASS | Manual alias unique: growth_time_to | growth_traits.Rd |
| PASS | Manual alias present: growth_mixed |  |
| PASS | Manual alias unique: growth_mixed | longitudinal_growth.Rd |
| PASS | Manual alias present: growth_mixed_diagnose |  |
| PASS | Manual alias unique: growth_mixed_diagnose | longitudinal_growth.Rd |
| PASS | Manual alias present: growth_smooth |  |
| PASS | Manual alias unique: growth_smooth | flexible_growth.Rd |
| PASS | Manual alias present: growth_smooth_predict |  |
| PASS | Manual alias unique: growth_smooth_predict | flexible_growth.Rd |
| PASS | Manual alias present: growth_derivative |  |
| PASS | Manual alias unique: growth_derivative | flexible_growth.Rd |
| PASS | Manual alias present: growth_acceleration |  |
| PASS | Manual alias unique: growth_acceleration | flexible_growth.Rd |
| PASS | Manual alias present: growth_smooth_traits |  |
| PASS | Manual alias unique: growth_smooth_traits | flexible_growth.Rd |
| PASS | Manual alias present: growth_fpca |  |
| PASS | Manual alias unique: growth_fpca | functional_growth.Rd |
| PASS | Manual alias present: growth_functional |  |
| PASS | Manual alias unique: growth_functional | functional_growth.Rd |
| PASS | Manual alias present: growth_curve_coefficients |  |
| PASS | Manual alias unique: growth_curve_coefficients | growth_manova.Rd |
| PASS | Manual alias present: growth_manova |  |
| PASS | Manual alias unique: growth_manova | growth_manova.Rd |
| PASS | Manual alias present: growth_boot |  |
| PASS | Manual alias unique: growth_boot | bootstrap_uncertainty.Rd |
| PASS | Manual alias present: growth_boot_ci |  |
| PASS | Manual alias unique: growth_boot_ci | bootstrap_uncertainty.Rd |
| PASS | Manual alias present: growth_boot_traits |  |
| PASS | Manual alias unique: growth_boot_traits | bootstrap_uncertainty.Rd |
| PASS | Manual alias present: growth_selection_stability |  |
| PASS | Manual alias unique: growth_selection_stability | bootstrap_uncertainty.Rd |
| PASS | Manual alias present: growth_prior |  |
| PASS | Manual alias unique: growth_prior | bayesian_growth.Rd |
| PASS | Manual alias present: growth_bayes |  |
| PASS | Manual alias unique: growth_bayes | bayesian_growth.Rd |
| PASS | Manual alias present: growth_prior_predict |  |
| PASS | Manual alias unique: growth_prior_predict | bayesian_growth.Rd |
| PASS | Manual alias present: growth_pp_check |  |
| PASS | Manual alias unique: growth_pp_check | bayesian_growth.Rd |
| PASS | Manual alias present: growth_bayes_diagnose |  |
| PASS | Manual alias unique: growth_bayes_diagnose | bayesian_growth.Rd |
| PASS | Manual alias present: growth_posterior_traits |  |
| PASS | Manual alias unique: growth_posterior_traits | bayesian_growth.Rd |
| PASS | Manual alias present: growth_loo |  |
| PASS | Manual alias unique: growth_loo | bayesian_model_evaluation.Rd |
| PASS | Manual alias present: growth_model_average |  |
| PASS | Manual alias unique: growth_model_average | bayesian_model_evaluation.Rd |
| PASS | growth_smooth Rd usage synchronized with source unit argument |  |
| PASS | 0.3.0 function mapped to expected manual: growth_mixed | longitudinal_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_mixed_diagnose | longitudinal_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_smooth | flexible_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_smooth_predict | flexible_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_derivative | flexible_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_acceleration | flexible_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_smooth_traits | flexible_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_fpca | functional_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_functional | functional_growth.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_curve_coefficients | growth_manova.Rd |
| PASS | 0.3.0 function mapped to expected manual: growth_manova | growth_manova.Rd |
| FAIL | Eighteen vignettes present through version 0.3.0 | 19 found |
| PASS | Vignette instructional depth: v00-overview.Rmd | 275 lines; threshold 100 |
| PASS | Vignette instructional depth: v01-data-design-validation.Rmd | 163 lines; threshold 100 |
| PASS | Vignette instructional depth: v02-classical-growth-analysis.Rmd | 134 lines; threshold 100 |
| PASS | Vignette instructional depth: v03-leaf-traits-and-canopy.Rmd | 132 lines; threshold 100 |
| PASS | Vignette instructional depth: v04-crop-growth-integrals.Rmd | 110 lines; threshold 100 |
| PASS | Vignette instructional depth: v05-partitioning-allometry.Rmd | 130 lines; threshold 100 |
| PASS | Vignette instructional depth: v06-foundations-to-advanced-tutorial.Rmd | 615 lines; threshold 500 |
| PASS | Vignette instructional depth: v07-parametric-model-library.Rmd | 327 lines; threshold 300 |
| PASS | Vignette instructional depth: v08-starting-values-and-multistart.Rmd | 353 lines; threshold 300 |
| PASS | Vignette instructional depth: v09-model-comparison-diagnostics.Rmd | 343 lines; threshold 300 |
| PASS | Vignette instructional depth: v10-derived-growth-traits.Rmd | 347 lines; threshold 300 |
| PASS | Vignette instructional depth: v11-parametric-growth-workflow.Rmd | 1200 lines; threshold 1000 |
| PASS | Vignette instructional depth: v12-longitudinal-mixed-effects.Rmd | 588 lines; threshold 500 |
| PASS | Vignette instructional depth: v13-flexible-smoothing-derivatives.Rmd | 496 lines; threshold 450 |
| PASS | Vignette instructional depth: v14-shape-constrained-growth.Rmd | 311 lines; threshold 300 |
| PASS | Vignette instructional depth: v15-functional-growth-fpca.Rmd | 423 lines; threshold 400 |
| PASS | Vignette instructional depth: v16-multivariate-growth-manova.Rmd | 385 lines; threshold 350 |
| PASS | Vignette instructional depth: v17-longitudinal-flexible-workflow.Rmd | 1094 lines; threshold 1000 |
| PASS | Vignette instructional depth: v18-design-aware-bootstrap.Rmd | 474 lines; threshold 100 |
| PASS | Vignette bibliography present |  |
| PASS | Vignette citation key present in bibliography: AntenAckerly2001 |  |
| PASS | Vignette citation key present in bibliography: ArchontoulisMiguez2015 |  |
| PASS | Vignette citation key present in bibliography: DavisonHinkley1997 |  |
| PASS | Vignette citation key present in bibliography: GoudriaanMonteith1990 |  |
| PASS | Vignette citation key present in bibliography: Hunt1990 |  |
| PASS | Vignette citation key present in bibliography: KeulsGarretsen1982 |  |
| PASS | Vignette citation key present in bibliography: Mammen1992 |  |
| PASS | Vignette citation key present in bibliography: Mirman2014 |  |
| PASS | Vignette citation key present in bibliography: MischanEtAl2015 |  |
| PASS | Vignette citation key present in bibliography: PinheiroBates2000 |  |
| PASS | Vignette citation key present in bibliography: Poorter1989 |  |
| PASS | Vignette citation key present in bibliography: PyaWood2015 |  |
| PASS | Vignette citation key present in bibliography: RamsaySilverman2005 |  |
| PASS | Vignette citation key present in bibliography: Richards1959 |  |
| PASS | Vignette citation key present in bibliography: ShipleyHunt1996 |  |
| PASS | Vignette citation key present in bibliography: WangChiouMuller2016 |  |
| PASS | Vignette citation key present in bibliography: YinEtAl2003 |  |
| PASS | Vignette citation key present in bibliography: YinEtAl2003Erratum |  |
| FAIL | No unused core bibliography keys | Buerkner2017, VehtariEtAl2021, VehtariGelmanGabry2017, YaoEtAl2018 |
| PASS | 0.3.0 vignette declares shared bibliography: v12-longitudinal-mixed-effects.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v13-flexible-smoothing-derivatives.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v14-shape-constrained-growth.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v15-functional-growth-fpca.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v16-multivariate-growth-manova.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v17-longitudinal-flexible-workflow.Rmd |  |
| PASS | 0.3.0 vignette declares shared bibliography: v18-design-aware-bootstrap.Rmd |  |
| FAIL | Sixteen core references have two-source audit records | 22 rows |
| PASS | All reference verification rows marked MATCH |  |
| PASS | Every reference row names two distinct verification sources |  |
| PASS | All 0.3.0 core references appear in verification CSV |  |
| PASS | 0.3.0 audited reference appears in bibliography: Mirman2014 |  |
| PASS | 0.3.0 audited reference appears in bibliography: MischanEtAl2015 |  |
| PASS | 0.3.0 audited reference appears in bibliography: PinheiroBates2000 |  |
| PASS | 0.3.0 audited reference appears in bibliography: PyaWood2015 |  |
| PASS | 0.3.0 audited reference appears in bibliography: RamsaySilverman2005 |  |
| PASS | 0.3.0 audited reference appears in bibliography: WangChiouMuller2016 |  |
| PASS | 0.3.0 reference audit documents: Pinheiro & Bates |  |
| PASS | 0.3.0 reference audit documents: Mirman |  |
| PASS | 0.3.0 reference audit documents: Pya & Wood |  |
| PASS | 0.3.0 reference audit documents: Ramsay & Silverman |  |
| PASS | 0.3.0 reference audit documents: Wang, Chiou & Müller |  |
| PASS | 0.3.0 reference audit documents: 16 audited core references |  |
| PASS | Teaching dataset present: maize_destructive.csv |  |
| PASS | Teaching dataset row count: maize_destructive.csv | 144 rows |
| PASS | Teaching dataset present: bean_repeated.csv |  |
| PASS | Teaching dataset row count: bean_repeated.csv | 192 rows |
| PASS | Teaching dataset present: soybean_partition.csv |  |
| PASS | Teaching dataset row count: soybean_partition.csv | 50 rows |
| PASS | Teaching dataset present: sunflower_sigmoid.csv |  |
| PASS | Teaching dataset row count: sunflower_sigmoid.csv | 216 rows |
| PASS | Teaching dataset present: wheat_expolinear.csv |  |
| PASS | Teaching dataset row count: wheat_expolinear.csv | 192 rows |
| PASS | Teaching dataset present: soybean_irregular.csv |  |
| PASS | Teaching dataset row count: soybean_irregular.csv | 402 rows |
| PASS | bean_repeated schema matches repeated phenotyping example |  |
| PASS | soybean_irregular schema matches irregular phenotyping example |  |
| PASS | Maize destructive data have 12 persistent plots |  |
| PASS | Maize destructive data have 72 plot-time means before aggregation |  |
| PASS | Maize destructive data have two subsamples per plot-time |  |
| PASS | Bean repeated data have 32 persistent plants |  |
| PASS | Every bean plant has six repeated times |  |
| PASS | Soybean irregular data have 48 persistent plants |  |
| PASS | Soybean irregular plants have 7 to 10 observations | 7-10 |
| PASS | Soybean irregular data have two water regimes |  |
| PASS | Soybean irregular trajectories share positive common support | 0.0 to 70.0 |
| PASS | Soybean irregular data use 11 potential observation days |  |
| PASS | Soybean partition components close to total mass | max deviation 2.14e-07 |
| PASS | Logistic midpoint equals half asymptote |  |
| PASS | Gompertz inflection response equals A/e |  |
| PASS | Richards shape=1 equals logistic parameterization |  |
| PASS | Corrected beta growth satisfies W(0)=0 and W(te)=wmax |  |
| PASS | Expolinear late finite-difference slope approaches cm | 11.9999999966 |
| PASS | AGR known truth |  |
| PASS | RGR known truth |  |
| PASS | NAR known truth finite and positive |  |
| PASS | Classical functions retain explicit recycling guard |  |
| PASS | Discrete AR1 is unit-nested |  |
| PASS | Continuous-time AR1 is unit-nested |  |
| PASS | AR1 integer-time guard implemented |  |
| PASS | Power residual variance structure implemented |  |
| PASS | Exponential residual variance structure implemented |  |
| PASS | Group-specific residual variance implemented |  |
| PASS | Destructive longitudinal aggregation is explicitly recorded |  |
| PASS | Population smoothing protects equal persistent-unit weighting |  |
| PASS | Smoothing-spline native derivatives implemented |  |
| PASS | Support-aware one-sided second differences implemented |  |
| PASS | SCAM monotone increasing/decreasing bases implemented |  |
| PASS | Grid FPCA rejects non-overlapping support |  |
| PASS | Grid FPCA uses L2 discretization scaling |  |
| PASS | fdapace FVE and fixed-component contracts implemented |  |
| PASS | refund irregular long-form contract implemented |  |
| PASS | Orthogonal coefficient layer rejects mismatched harvest grids |  |
| PASS | MANOVA layer implements requested multivariate statistic |  |
| PASS | Optional backend guarded with requireNamespace: nlme |  |
| PASS | Optional backend guarded with requireNamespace: mgcv |  |
| PASS | Optional backend guarded with requireNamespace: scam |  |
| PASS | Optional backend guarded with requireNamespace: fdapace |  |
| PASS | Optional backend guarded with requireNamespace: refund |  |
| PASS | Optional backend guarded with requireNamespace: minpack.lm |  |
| PASS | Package source does not install dependencies automatically |  |
| FAIL | Expected complete test-source set present | test-bayesian-growth.R, test-bootstrap-uncertainty.R, test-classical-rates.R, test-classical-workflow.R, test-data-design.R, test-foundation-regressions-020.R, test-functional-growth.R, test-growth-manova.R, test-longitudinal-mixed.R, test-parametric-models.R, test-parametric-traits.R, test-partition-allometry.R, test-smooth-growth.R |
| PASS | 0.3.0 API represented in test sources: growth_mixed | 4 calls |
| PASS | 0.3.0 API represented in test sources: growth_mixed_diagnose | 1 calls |
| PASS | 0.3.0 API represented in test sources: growth_smooth | 4 calls |
| PASS | 0.3.0 API represented in test sources: growth_derivative | 1 calls |
| PASS | 0.3.0 API represented in test sources: growth_acceleration | 1 calls |
| PASS | 0.3.0 API represented in test sources: growth_fpca | 3 calls |
| PASS | 0.3.0 API represented in test sources: growth_curve_coefficients | 3 calls |
| PASS | 0.3.0 API represented in test sources: growth_manova | 1 calls |
| PASS | Consolidated 0.3.0 public API examples file present |  |
| PASS | API examples include at least three calls: growth_agr | 3 calls |
| PASS | API examples include at least three calls: growth_allometry | 3 calls |
| PASS | API examples include at least three calls: growth_cgr | 3 calls |
| PASS | API examples include at least three calls: growth_classical | 3 calls |
| PASS | API examples include at least three calls: growth_data | 5 calls |
| PASS | API examples include at least three calls: growth_design | 5 calls |
| PASS | API examples include at least three calls: growth_example_data | 9 calls |
| PASS | API examples include at least three calls: growth_indices | 3 calls |
| PASS | API examples include at least three calls: growth_lad | 3 calls |
| PASS | API examples include at least three calls: growth_lai | 3 calls |
| PASS | API examples include at least three calls: growth_lar | 3 calls |
| PASS | API examples include at least three calls: growth_lmr | 3 calls |
| PASS | API examples include at least three calls: growth_nar | 3 calls |
| PASS | API examples include at least three calls: growth_partition | 3 calls |
| PASS | API examples include at least three calls: growth_plan | 3 calls |
| PASS | API examples include at least three calls: growth_plot | 3 calls |
| PASS | API examples include at least three calls: growth_rgr | 3 calls |
| PASS | API examples include at least three calls: growth_sla | 3 calls |
| PASS | API examples include at least three calls: growth_validate | 3 calls |
| PASS | API examples include at least three calls: growth_models | 4 calls |
| PASS | API examples include at least three calls: growth_start | 3 calls |
| PASS | API examples include at least three calls: growth_fit | 3 calls |
| PASS | API examples include at least three calls: growth_multistart | 3 calls |
| PASS | API examples include at least three calls: growth_predict | 3 calls |
| PASS | API examples include at least three calls: growth_compare | 3 calls |
| PASS | API examples include at least three calls: growth_diagnose | 3 calls |
| PASS | API examples include at least three calls: growth_traits | 3 calls |
| PASS | API examples include at least three calls: growth_inflection | 3 calls |
| PASS | API examples include at least three calls: growth_maxrate | 3 calls |
| PASS | API examples include at least three calls: growth_time_to | 3 calls |
| PASS | API examples include at least three calls: growth_mixed | 3 calls |
| PASS | API examples include at least three calls: growth_mixed_diagnose | 3 calls |
| PASS | API examples include at least three calls: growth_smooth | 3 calls |
| PASS | API examples include at least three calls: growth_smooth_predict | 3 calls |
| PASS | API examples include at least three calls: growth_derivative | 3 calls |
| PASS | API examples include at least three calls: growth_acceleration | 3 calls |
| PASS | API examples include at least three calls: growth_smooth_traits | 3 calls |
| PASS | API examples include at least three calls: growth_fpca | 3 calls |
| PASS | API examples include at least three calls: growth_functional | 3 calls |
| PASS | API examples include at least three calls: growth_curve_coefficients | 3 calls |
| PASS | API examples include at least three calls: growth_manova | 3 calls |
| FAIL | API examples include at least three calls: growth_boot | 0 calls |
| FAIL | API examples include at least three calls: growth_boot_ci | 0 calls |
| FAIL | API examples include at least three calls: growth_boot_traits | 0 calls |
| FAIL | API examples include at least three calls: growth_selection_stability | 0 calls |
| FAIL | API examples include at least three calls: growth_prior | 0 calls |
| FAIL | API examples include at least three calls: growth_bayes | 0 calls |
| FAIL | API examples include at least three calls: growth_prior_predict | 0 calls |
| FAIL | API examples include at least three calls: growth_pp_check | 0 calls |
| FAIL | API examples include at least three calls: growth_bayes_diagnose | 0 calls |
| FAIL | API examples include at least three calls: growth_posterior_traits | 0 calls |
| FAIL | API examples include at least three calls: growth_loo | 0 calls |
| FAIL | API examples include at least three calls: growth_model_average | 0 calls |
| PASS | Flexible 0.3.0 examples identify persistent plant and treatment group |  |
| PASS | Mixed-model examples guard optional nlme backend |  |
| PASS | Irregular soybean teaching data used in consolidated examples |  |
| PASS | No em dash in package prose/source |  |
| PASS | No ChatGPT/UI citation artifacts in distributed files |  |
| PASS | No provisional TODO/FIXME/placeholder markers |  |
| PASS | No Python cache directories in source tree |  |
| PASS | Teaching-data SHA256 manifest refreshed for six datasets | inst/metadata/teaching_data_checksums.sha256 |
| PASS | 0.3.0 implementation specification covers: 41 functions |  |
| PASS | 0.3.0 implementation specification covers: Longitudinal mixed-effects layer |  |
| PASS | 0.3.0 implementation specification covers: Flexible trajectory layer |  |
| PASS | 0.3.0 implementation specification covers: Functional growth layer |  |
| PASS | 0.3.0 implementation specification covers: Orthogonal growth components and MANOVA |  |
| PASS | 0.3.0 implementation specification covers: frozen source snapshots |  |
| PASS | Historical 0.2.0 freeze manifest retained unchanged in development tree |  |

## Required local R release gates

Run from a clean machine with R >= 4.2.0:

```r
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "ggplot2", "rlang", "minpack.lm", "nlme", "mgcv", "scam", "refund", "fdapace"))
devtools::document("agriGrowthFlow")
devtools::test("agriGrowthFlow")
devtools::install("agriGrowthFlow", build_vignettes = TRUE)
devtools::check("agriGrowthFlow", cran = TRUE, manual = TRUE)
```

Then build and check the exact immutable tarball:

```sh
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_0.3.0.tar.gz
```

## High-priority numerical and design controls for the local run

1. Logistic midpoint must equal half asymptote.
2. Gompertz inflection response must equal `A/e`.
3. Richards with `shape = 1` must reproduce the package logistic curve.
4. Corrected beta growth must satisfy `W(0) = 0` and `W(te) = wmax`.
5. Expolinear late finite-difference slope must approach `cm`.
6. Destructive maize data must reduce from 144 rows to 72 plot-time means before mixed modeling.
7. `correlation = "ar1"` must reject noninteger time; `"car1"` must remain available for continuous time.
8. A known linear smooth must return first derivative near its generating slope and second derivative near zero.
9. Grid FPCA must return 32 bean scores or 48 irregular-soybean scores when those complete teaching datasets are used.
10. Grid FPCA must reject persistent units without positive common support.
11. Growth-curve MANOVA must refuse mismatched observed time grids rather than interpolate silently.
12. Ambiguous vector recycling in the classical foundation must continue to raise an error.

## Interpretation

A zero-failure static battery establishes internal source coherence at the level tested here. It is not a substitute for parsing, executing, regenerating documentation, rendering vignettes, and checking the package with R. The source snapshot may be frozen and hashed, but it must not be represented as an `R CMD build` artifact until the local R gates succeed.
