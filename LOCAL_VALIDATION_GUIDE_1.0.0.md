# agriGrowthFlow 1.0.0: Detailed Local Validation Guide

## Purpose

This document defines the local release-validation procedure for the frozen `agriGrowthFlow` 1.0.0 source snapshot.

The frozen ZIP and TAR.GZ delivered with this release were created in an environment without R. They are therefore source snapshots, not tarballs produced by `R CMD build`.

A release should be called runtime-validated only after the exact source tree passes the R gates described below.

The central rule is simple:

> Validate the same source that will be built, and run `R CMD check --as-cran` on the exact tarball that will be retained as the release artifact.

Do not edit the checked tarball after validation.

## 1. Files to keep together

Keep these files in one validation directory:

- `agriGrowthFlow_1.0.0_frozen_source_snapshot.tar.gz`;
- `agriGrowthFlow_1.0.0_frozen_source_snapshot.zip`;
- `agriGrowthFlow_1.0.0_archive_checksums.sha256`;
- `ARCHIVE_VERIFICATION_1.0.0.md`;
- the package source tree after extraction.

The source tree itself contains:

- `SHA256SUMS_1.0.0.txt` for internal source-file integrity;
- `TREE_1.0.0.txt` for the frozen tree listing;
- `FREEZE_MANIFEST_1.0.0.md` for release provenance;
- `LOCAL_VALIDATION_1.0.0.md` for the static-validation log;
- this detailed local-validation guide.

## 2. Minimum software

### R

Use R 4.2.0 or newer because the package declares:

```text
Depends: R (>= 4.2.0)
```

For release validation, a current supported R release is preferable.

Record the exact R version with:

```r
R.version.string
```

### Windows

Install the Rtools version that matches the installed R release.

Confirm that the build toolchain is visible:

```r
pkgbuild::has_build_tools(debug = TRUE)
```

### Linux

Install the standard compiler and development toolchain required by R and any source packages used during testing.

On Debian or Ubuntu this commonly includes `build-essential`, but use the package-manager instructions appropriate to the local system.

### macOS

Install the Xcode Command Line Tools and any compiler components required by the selected R release.

## 3. Required R packages for the core validation

Install the release and documentation tooling:

```r
install.packages(c(
  "devtools",
  "roxygen2",
  "testthat",
  "rmarkdown",
  "knitr"
))
```

Install the declared analytical backends used by the non-Bayesian tests and vignettes:

```r
install.packages(c(
  "minpack.lm",
  "nlme",
  "mgcv",
  "scam",
  "refund",
  "fdapace"
))
```

The package itself imports `ggplot2` and `rlang`, so ensure they are installed as well:

```r
install.packages(c("ggplot2", "rlang"))
```

## 4. Optional Bayesian validation stack

The Bayesian layer is optional but should be validated before making Bayesian release claims.

Install:

```r
install.packages(c(
  "brms",
  "posterior",
  "loo"
))
```

If using `cmdstanr`, install it from its supported repository and install CmdStan following the current `cmdstanr` documentation.

Confirm the Stan toolchain before running Bayesian tests.

The package deliberately does not install Stan or any dependency automatically.

## 5. Verify the frozen archive before extraction

### Linux or macOS

From the directory containing the release files:

```bash
sha256sum -c agriGrowthFlow_1.0.0_archive_checksums.sha256
```

Both snapshot archives must report `OK`.

### Windows PowerShell

Read the expected values from `agriGrowthFlow_1.0.0_archive_checksums.sha256`, then calculate:

```powershell
Get-FileHash .\agriGrowthFlow_1.0.0_frozen_source_snapshot.tar.gz -Algorithm SHA256
Get-FileHash .\agriGrowthFlow_1.0.0_frozen_source_snapshot.zip -Algorithm SHA256
```

The calculated values must match the supplied checksum ledger exactly.

## 6. Extract to a clean directory

Create a clean validation directory.

### TAR.GZ

```bash
tar -xzf agriGrowthFlow_1.0.0_frozen_source_snapshot.tar.gz
```

### ZIP

Use the operating-system extractor or:

```powershell
Expand-Archive .\agriGrowthFlow_1.0.0_frozen_source_snapshot.zip -DestinationPath .\zip_extract
```

The final package root should be named `agriGrowthFlow`.

## 7. Verify internal source-file checksums

Do this before running any tool that changes generated documentation.

### Linux or macOS

Enter the package root and run:

```bash
sha256sum -c SHA256SUMS_1.0.0.txt
```

Every listed file must report `OK`.

### Windows PowerShell

The internal checksum file uses standard SHA-256 ledger syntax.

A PowerShell verification loop can be used, or the values can be checked with Git for Windows, WSL, or another trusted SHA-256 tool.

Do not proceed if any source-file hash differs.

## 8. Preserve an immutable copy

Before running `roxygen2`, create two directories:

```text
validation/
  frozen/agriGrowthFlow/
  working/agriGrowthFlow/
```

The `frozen` directory must never be modified.

Run all documentation regeneration and runtime testing in `working/agriGrowthFlow`.

This makes later differences auditable.

## 9. Run the source-level static validator

Python is optional for the R release, but the source snapshot includes a static validator.

From the working package root:

```bash
python tools/static_validate_1.0.0.py
```

The frozen source result should be:

```text
559 PASS, 0 FAIL
```

If a different result is obtained, investigate before continuing.

The static battery cannot replace R runtime validation.

## 10. Record the R environment

Start a clean R session and save:

```r
sessionInfo()
```

A convenient record is:

```r
writeLines(capture.output(sessionInfo()), "sessionInfo_before_validation.txt")
```

Also record package versions:

```r
pkgs <- c(
  "ggplot2", "rlang", "minpack.lm", "nlme", "mgcv", "scam",
  "refund", "fdapace", "brms", "posterior", "loo", "cmdstanr",
  "knitr", "rmarkdown", "testthat", "roxygen2", "devtools"
)
ver <- vapply(pkgs, function(p) {
  if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else NA_character_
}, character(1))
write.csv(data.frame(package = pkgs, version = ver), "dependency_versions.csv", row.names = FALSE)
```

## 11. Regenerate roxygen documentation

From the parent directory of the working package:

```r
roxygen2::roxygenise("agriGrowthFlow")
```

This must regenerate `NAMESPACE` and `man/` without an unexpected public API change.

## 12. Compare regenerated documentation with the frozen contract

### Linux or macOS

```bash
diff -u frozen/agriGrowthFlow/NAMESPACE working/agriGrowthFlow/NAMESPACE

diff -ru frozen/agriGrowthFlow/man working/agriGrowthFlow/man
```

### Windows PowerShell

Use a directory comparison tool, Git, or:

```powershell
Compare-Object \
  (Get-Content .\frozen\agriGrowthFlow\NAMESPACE) \
  (Get-Content .\working\agriGrowthFlow\NAMESPACE)
```

Review any manual differences explicitly.

Expected harmless changes can include formatting produced by a newer roxygen2 release.

Unexpected changes in exports, S3 registrations, aliases, signatures, or argument documentation are release blockers until understood.

## 13. Re-run static validation after roxygen regeneration

From the working package root:

```bash
python tools/static_validate_1.0.0.py
```

A generated-documentation change can reveal an inconsistency that was not present in the frozen manual files.

## 14. Run unit tests

From R:

```r
devtools::test("agriGrowthFlow", reporter = "summary")
```

Or from the shell:

```bash
Rscript -e "devtools::test('agriGrowthFlow', reporter='summary')"
```

All non-Bayesian tests must pass.

The suite includes tests for:

- data and design validation;
- classical rates and identities;
- parametric curves and derived traits;
- longitudinal mixed models;
- smooth trajectories and derivatives;
- functional growth analysis;
- bootstrap uncertainty;
- biological events and decision functions;
- the consolidated 1.0.0 workflow, audit, report, and export layer.

## 15. Run the optional Bayesian tests

The Bayesian tests are deliberately gated because Stan compilation can be expensive.

After confirming a working Stan toolchain, set:

### Linux or macOS

```bash
export AGRIGROWTHFLOW_RUN_BAYES_TESTS=true
```

### Windows PowerShell

```powershell
$env:AGRIGROWTHFLOW_RUN_BAYES_TESTS = "true"
```

Then run:

```r
devtools::test("agriGrowthFlow", filter = "bayesian-growth", reporter = "summary")
```

Record:

- backend used;
- compiler version;
- CmdStan version when applicable;
- elapsed time;
- any divergent transitions;
- maximum R-hat;
- minimum bulk ESS;
- minimum tail ESS.

Do not treat successful compilation alone as a Bayesian validation result.

## 16. Render every vignette

Version 1.0.0 contains 31 extensive English vignettes.

Build them in a clean R session:

```r
devtools::build_vignettes("agriGrowthFlow")
```

Also test individual rendering when diagnosing a failure:

```r
rmarkdown::render("agriGrowthFlow/vignettes/v30-foundations-to-release-tutorial.Rmd")
```

Inspect the rendered output for:

- mathematical symbols;
- tables;
- figures;
- code wrapping;
- missing citations;
- broken cross-references;
- accidental console warnings;
- package functions that changed signatures;
- text that implies a method was run when the code chunk is not executed.

## 17. Check every teaching dataset

The release contains ten simulated teaching datasets.

Confirm that all load from the installed package:

```r
sets <- c(
  "maize_destructive", "bean_repeated", "soybean_partition",
  "sunflower_sigmoid", "wheat_expolinear", "soybean_irregular",
  "coffee_diphasic", "bean_defoliation", "maize_density",
  "tree_competition"
)

for (nm in sets) {
  z <- growth_example_data(nm)
  stopifnot(is.data.frame(z), nrow(z) > 0)
}
```

Confirm that these datasets remain described as simulated teaching data, not field evidence.

## 18. Numerical known-truth controls

Run numerical controls independently of the ordinary test suite.

The purpose is to detect silent changes in formulas, optimizer behavior, or numerical differentiation.

### 18.1 AGR

```r
stopifnot(all.equal(
  growth_agr(10, 16, 2, 5),
  2
))
```

### 18.2 RGR

```r
expected <- (log(16) - log(10)) / 3
stopifnot(all.equal(
  growth_rgr(10, 16, 2, 5),
  expected
))
```

### 18.3 LAR identity

For positive values:

```r
leaf_area <- 0.24
leaf_mass <- 6
plant_mass <- 30

lar <- growth_lar(leaf_area, plant_mass)
sla <- growth_sla(leaf_area, leaf_mass)
lmr <- growth_lmr(leaf_mass, plant_mass)

stopifnot(all.equal(lar, sla * lmr))
```

### 18.4 Logistic inflection and 50-percent time

Fit or construct a known logistic trajectory and verify that the inflection time agrees with the 50-percent asymptotic time within numerical tolerance.

For a fitted Logistic object:

```r
inf <- growth_inflection(fit_logistic)
t50 <- growth_time_to(fit_logistic, fraction = 0.5)
stopifnot(abs(inf$time - t50$time) < 1e-6)
```

Use the actual returned column names if a newer R/roxygen regeneration documents them differently, but do not change the mathematical criterion.

### 18.5 Richards special case

Verify that the Richards parameterization used by the package reduces to the Logistic form at the documented shape value.

This control should use the package model registry and identical parameters on a dense time grid.

### 18.6 Beta-growth endpoints

For the corrected Yin beta-growth implementation, verify:

```text
W(0) = 0
W(te) = Wmax
```

within numerical tolerance.

The package follows the published erratum for the exponent.

### 18.7 Expolinear late-growth rate

On a sufficiently late time grid, confirm that the numerical slope approaches the declared maximum absolute rate parameter.

Do not create an artificial asymptote for an expolinear model.

### 18.8 Smoother derivatives

Simulate a simple polynomial with known first and second derivatives.

Fit a dense low-noise smoother and confirm that numerical derivatives approach the analytical values away from the support boundaries.

### 18.9 Mixed-model persistence

For `bean_repeated`, confirm that:

- the same plant remains the persistent unit;
- CAR(1) uses actual time spacing;
- no row-level independent replication is introduced by preprocessing.

### 18.10 FPCA

Check:

- finite eigenvalues;
- non-increasing retained eigenvalues;
- finite scores;
- explained variance between 0 and 1;
- reconstruction only over supported temporal domains.

### 18.11 Bootstrap

For a representative parametric fit:

```r
b <- growth_boot(fit_logistic, R = 499, seed = 1001)
stopifnot(b$success_rate >= 0.80)
```

For longitudinal resampling, verify that cluster bootstrap resamples complete persistent-unit trajectories.

Repeat with a larger `R` if interval stability is being assessed for publication.

### 18.12 Bayesian diagnostics

For each Bayesian example intended for release use, require at minimum:

- R-hat no greater than the release threshold used by `growth_bayes_diagnose()`;
- adequate bulk and tail ESS;
- zero or scientifically resolved divergent transitions;
- acceptable prior predictive behavior;
- acceptable posterior predictive behavior;
- inspection of Pareto-k diagnostics before using PSIS-LOO weights.

### 18.13 Multiphase ordering

Confirm that fitted phase centers remain strictly ordered.

Repeat the fit with several seeds and verify that comparable minima are recovered.

### 18.14 Stability points

Recompute fourth-derivative stability points with a denser numerical grid.

They should be stable to reasonable increases in grid density.

### 18.15 Defoliation

Confirm that reconstructed total mass, leaf mass, and leaf area remain physically meaningful.

Repeat with a smaller integration step and verify numerical stability.

### 18.16 Competition

Set the off-diagonal competition matrix to zero.

The coupled simulator should reduce to independent logistic-like trajectories for each plant.

Repeat with a smaller RK4 time step and confirm stability.

### 18.17 Threshold equivalence

For a Logistic fit, compare the 50-percent result from `growth_threshold(..., type = "fraction")` with `growth_time_to(..., fraction = 0.5)`.

They should agree within numerical tolerance.

### 18.18 Scheduling and harvest bounds

Confirm that all proposed schedule and harvest times remain inside the interval explicitly supplied to the functions.

### 18.19 Monte Carlo power

Run `growth_power()` with progressively larger `n_sim`.

The Monte Carlo estimate should stabilize and its simulation noise should decrease.

### 18.20 Consolidated workflow contract

Create a planning-only workflow:

```r
w0 <- growth_workflow(
  growth_example_data("sunflower_sigmoid"),
  time = "day",
  response = "biomass_g",
  execute = FALSE,
  seed = 2001
)

a0 <- growth_workflow_audit(w0)
stopifnot(!any(a0$status == "FAIL"))
stopifnot(is.null(w0$core))
```

Then execute an explicit parametric workflow:

```r
w1 <- growth_workflow(
  growth_example_data("sunflower_sigmoid"),
  time = "day",
  response = "biomass_g",
  strategy = "parametric",
  models = c("logistic", "gompertz"),
  n_start = 5,
  seed = 2002
)

stopifnot(inherits(w1, "agri_growth_workflow"))
stopifnot(!is.null(w1$core))
stopifnot(is.data.frame(growth_table(w1, "traits")))
```

### 18.21 Export round trip

```r
td <- tempfile("agf_bundle_")
growth_export(w1, td, format = "bundle")

required <- c(
  "object.rds",
  "workflow_audit.csv",
  "method_guide.csv",
  "report.md"
)
stopifnot(all(file.exists(file.path(td, required))))

w2 <- readRDS(file.path(td, "object.rds"))
stopifnot(inherits(w2, "agri_growth_workflow"))
```

## 19. Run `R CMD build`

After unit tests and vignette rendering pass, build from the parent directory of the working tree:

```bash
R CMD build agriGrowthFlow
```

The expected output name is:

```text
agriGrowthFlow_1.0.0.tar.gz
```

Do not rename a tarball from another version to this name.

## 20. Freeze the built tarball checksum immediately

### Linux or macOS

```bash
sha256sum agriGrowthFlow_1.0.0.tar.gz > agriGrowthFlow_1.0.0_RCMD_BUILD.sha256
```

### Windows PowerShell

```powershell
Get-FileHash .\agriGrowthFlow_1.0.0.tar.gz -Algorithm SHA256 | Format-List
```

Record this hash before `R CMD check`.

The hash after `R CMD check` should be identical because checking should not modify the tarball.

## 21. Run `R CMD check --as-cran` on the exact tarball

```bash
R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz
```

Do not run the final CRAN-like check only on the source directory.

The exact built tarball is the object that must pass.

## 22. Inspect the check summary

Open:

```text
agriGrowthFlow.Rcheck/00check.log
```

Target:

```text
Status: OK
```

Any ERROR is a release blocker.

Any WARNING must be resolved or explicitly justified before release.

Any NOTE must be reviewed. A NOTE is not automatically harmless.

## 23. Inspect installed examples and vignettes inside the check directory

Review:

```text
agriGrowthFlow.Rcheck/
```

Check for:

- example errors;
- vignette failures;
- missing files;
- undeclared dependencies;
- namespace warnings;
- invalid URLs;
- documentation mismatches;
- non-portable file names;
- accidental large files.

## 24. Install the checked tarball into a clean library

Create a temporary library:

```r
lib <- tempfile("agf_lib_")
dir.create(lib)
```

Then from a shell:

```bash
R CMD INSTALL -l /path/to/agf_lib agriGrowthFlow_1.0.0.tar.gz
```

In a fresh R session:

```r
library(agriGrowthFlow, lib.loc = "/path/to/agf_lib")
packageVersion("agriGrowthFlow")
```

The version must be `1.0.0`.

## 25. Smoke-test the installed package

```r
library(agriGrowthFlow)

m <- growth_example_data("maize_destructive")
s <- growth_example_data("sunflower_sigmoid")

stopifnot(nrow(m) > 0, nrow(s) > 0)

g <- growth_data(
  m,
  time = "day",
  sampling = "destructive",
  experimental_unit = "plot_id",
  treatment = "nitrogen",
  total_mass = "total_mass_g",
  leaf_area = "leaf_area_m2"
)

stopifnot(inherits(growth_validate(g), "agri_growth_validation"))
stopifnot(inherits(growth_method_guide(g), "agri_growth_method_guide"))
```

Then run one installed-package parametric workflow and one report/export round trip.

## 26. Verify installed citation metadata

```r
citation("agriGrowthFlow")
```

The citation must identify package version 1.0.0.

## 27. Check DESCRIPTION and NEWS in the built tarball

Extract the `R CMD build` tarball to a separate directory and verify:

- `DESCRIPTION` says `Version: 1.0.0`;
- `NEWS.md` begins with 1.0.0;
- `inst/CITATION` identifies 1.0.0;
- no previous-version freeze manifests were unintentionally installed if excluded by `.Rbuildignore`;
- validation-only files are excluded as intended.

## 28. Inspect the tarball file list

### Linux or macOS

```bash
tar -tzf agriGrowthFlow_1.0.0.tar.gz > RCMD_BUILD_TREE_1.0.0.txt
```

Inspect for accidental files such as:

- `.Rhistory`;
- `.RData`;
- temporary editor files;
- compiled objects;
- caches;
- local credentials;
- raw private data;
- large unneeded outputs.

## 29. Reproducibility on a second platform

For a stable scientific release, repeat at least the core validation on a second operating system when practical.

A useful minimum is:

- Windows with current R and matching Rtools;
- Linux with current R.

Record platform-specific differences.

## 30. Final acceptance criteria

The 1.0.0 runtime release is accepted only when all applicable items are satisfied:

- [ ] archive SHA-256 matches the delivered frozen snapshot;
- [ ] all internal source-file hashes match before testing;
- [ ] static validation reports zero failures;
- [ ] roxygen regeneration produces no unexplained API change;
- [ ] all ordinary `testthat` tests pass;
- [ ] all 31 vignettes render;
- [ ] optional Bayesian tests pass when Bayesian claims are included;
- [ ] numerical known-truth controls pass;
- [ ] all ten simulated teaching datasets load;
- [ ] `R CMD build` creates `agriGrowthFlow_1.0.0.tar.gz`;
- [ ] SHA-256 of the built tarball is recorded;
- [ ] the exact built tarball passes `R CMD check --as-cran`;
- [ ] `00check.log` has no unresolved ERROR or WARNING;
- [ ] every NOTE has been reviewed;
- [ ] the tarball installs in a clean library;
- [ ] the installed package reports version 1.0.0;
- [ ] `citation("agriGrowthFlow")` is correct;
- [ ] release workflow, audit, report, and export smoke tests pass;
- [ ] final session information and dependency versions are archived;
- [ ] the checked tarball is not modified after validation.

## 31. What to archive after successful local validation

Keep:

```text
agriGrowthFlow_1.0.0.tar.gz
agriGrowthFlow_1.0.0_RCMD_BUILD.sha256
agriGrowthFlow.Rcheck/00check.log
RCMD_BUILD_TREE_1.0.0.txt
sessionInfo_before_validation.txt
dependency_versions.csv
Bayesian validation log, if run
rendered-vignette validation log
```

The frozen source snapshot delivered here should also be retained separately from the `R CMD build` tarball.

They serve different purposes:

- the frozen source snapshot documents the pre-runtime source state;
- the `R CMD build` tarball is the R-native release artifact that must pass the final CRAN-like check.

## 32. Recommended final local directory

```text
agriGrowthFlow_1.0.0_validation/
  frozen_source/
  working_source/
  release/
    agriGrowthFlow_1.0.0.tar.gz
    agriGrowthFlow_1.0.0_RCMD_BUILD.sha256
  check/
    agriGrowthFlow.Rcheck/
  logs/
    sessionInfo_before_validation.txt
    dependency_versions.csv
    vignette_render.log
    bayesian_validation.log
```

This separation avoids confusing generated runtime artifacts with the frozen source snapshot.

## Final note

Static integrity is necessary but not sufficient for an R release.

The decisive local release gate is:

```text
R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz
```

run on the exact tarball produced from the reviewed source tree, followed by inspection of the complete check log and numerical controls described above.
