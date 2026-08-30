agriGrowthFlow 1.0.0: runtime-validated release with vignette and documentation fixes

- Fix duplicate unit-time aggregation for MANOVA (flexible-prep.R): auto aggregate when duplicate unit-time exists even when sampling is unspecified, restoring growth_curve_coefficients and growth_manova tests.
- Guard log transformation on raw responses before aggregation in growth-manova.R to preserve surveillance of zero values that would be masked by mean aggregation.
- Fix SCAM constraint match.arg bug in smooth-growth.R: move match.arg to function level to avoid empty-choice error inside lapply, restoring v13/v14/v17 vignettes.
- Accept list of fits in growth_compare() (parametric-predict-compare.R) to support vignette usage growth_compare(list(...)).
- Fix vignette v30: compute shoot_mass_g from components, correct wheat_expolinear biomass_g_m2 column, make growth_changepoint calls per treatment, fix growth_compensation/group naming, growth_density plant_mass, growth_neighbor coordinates and growth_competition argument names, and fix growth_lad 4-arg legacy call to vector form.
- Add library(agriGrowthFlow) to v28 and v29 vignette setups to make them self-contained during R CMD check.
- Fix duplicated \item{time} in man/flexible_growth.Rd by merging time documentation to remove WARNING.
- Add utils::globalVariables and NAMESPACE imports for modifyList and stats::time to silence R code NOTES; add _pkgdown.yml to .Rbuildignore and handle cheatsheet/docs exclusion.
- Update README with remotes::install_github(build_vignettes=TRUE) and pak::pak instructions; add cheatsheet documentation reference.
- Add URL and BugReports to DESCRIPTION; exclude cheatsheet and docs from tarball via .Rbuildignore.
- Add pkgdown configuration (_pkgdown.yml) and GitHub Actions workflows (R-CMD-check pak matrix and pkgdown gh-pages deploy).
- Render cheatsheets PT/EN with Quarto (qmd + html) in cheatsheet/ outside tarball, with fixed seeds and honest model comparison tables.

Validation: static 561 PASS, 0 FAIL; testthat 0 failures (1 Bayesian skipped opt-in); R CMD build OK (1.0 MB); R CMD check --as-cran 2 NOTEs (New submission, Rd line widths) 0 WARNINGs 0 ERRORs; vignettes 31/31 OK; clean-lib smoke OK; SHA256 5eff7e21824334838c516a702ae58dbd94d8ac2d6fd504132540533dfadfc540.

TAR: D:/Walter/R/Pacotes_criados/agriGrowthFlow/validation/working/agriGrowthFlow_1.0.0.tar.gz (also at validation/release/ and origin root)
Site: https://wep69.github.io/agriGrowthFlow/ via pkgdown gh-pages
