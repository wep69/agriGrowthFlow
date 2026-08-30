# agriGrowthFlow 1.0.0 Freeze Manifest

## Freeze status

Version 1.0.0 is frozen as a consolidated source snapshot after source-level validation.

Static validation result: **561 PASS, 0 FAIL**.

Freeze timestamp (UTC): **2026-08-27T20:26:21Z**.

This execution environment does not contain R. Therefore the frozen TAR.GZ and ZIP are source snapshots, not tarballs produced by `R CMD build`. Definitive R runtime validation remains mandatory before calling the release CRAN-like validated.

## Frozen scope

- Package version: 1.0.0
- Public functions: 75
- Registered S3 methods: 41
- R source files: 22
- Rd manual files: 24
- Extensive English vignettes: 31
- Frozen simulated teaching datasets: 10
- Double-verified scientific reference records: 25
- Test source files: 15
- Files in the frozen package tree: 164

## Consolidated release additions

Version 1.0.0 stabilizes the complete 0.1.0 to 0.5.0 scientific architecture and adds six release-level functions:

- `growth_method_guide()` for transparent design- and objective-aware method shortlisting;
- `growth_workflow()` for planning-only or executed auditable workflows;
- `growth_workflow_audit()` for PASS, INFO, and FAIL release gates;
- `growth_table()` for standardized tabular extraction;
- `growth_report()` for reproducible Markdown analysis records;
- `growth_export()` for complete RDS archives, CSV review tables, and multi-file bundles.

Three release vignettes complete the instructional sequence: `v28-release-workflow-contract.Rmd`, `v29-reporting-audit-export.Rmd`, and `v30-foundations-to-release-tutorial.Rmd`.

## Scientific boundaries retained in the stable release

- The persistent experimental unit and sampling mechanism are declared before longitudinal interpretation.
- Destructive subsamples are not treated as repeated individual plants when a higher-level unit persists across harvest dates.
- Method-guide priorities are navigation rules, not model probabilities or proof that one method is uniquely correct.
- Automatic workflow selection does not choose a scientific conclusion from a single p-value, R-squared, AIC, or AICc value.
- Candidate model comparison is retained only for identical prepared observations.
- Bootstrap resampling must preserve the experimental hierarchy.
- Bayesian inference remains optional and requires prior checks, posterior checks, and MCMC diagnostics.
- Multiphase critical points are interpreted from the complete summed trajectory.
- Measured disturbance losses are not replaced by invented smooth-curve losses.
- Observation schedules remain heuristics rather than claims of D-optimality.
- Harvest optimization remains conditional on the fitted model and user-supplied biological and economic assumptions.
- RDS is the preferred complete archive because flat files cannot preserve nested fitted-model objects.

## Integrity model

`TREE_1.0.0.txt` records every file name in the frozen source tree, including the integrity files.

`SHA256SUMS_1.0.0.txt` contains SHA-256 hashes for every frozen file except the checksum ledger itself. This means that the tree inventory, freeze manifest, source code, manuals, tests, vignettes, datasets, validation instructions, and metadata are all protected by the internal ledger.

The checksum ledger cannot contain its own hash without creating a self-reference. Archive-level SHA-256 hashes are therefore stored outside the archives in `agriGrowthFlow_1.0.0_archive_checksums.sha256`. The archive-level hashes protect the checksum ledger itself.

The TAR.GZ and ZIP are independently extracted and verified after creation. Verification results are stored outside the archives in `ARCHIVE_VERIFICATION_1.0.0.md`.

## Local validation documents

Two complementary validation records are included:

- `LOCAL_VALIDATION_1.0.0.md` contains the complete source-level static-validation inventory;
- `LOCAL_VALIDATION_GUIDE_1.0.0.md` contains the detailed Windows, Linux, and R runtime procedure, including numerical controls, roxygen regeneration, testthat, all 31 vignettes, optional Bayesian validation, `R CMD build`, and `R CMD check --as-cran` on the exact built tarball.

A helper script is available as `tools/local_validate_1.0.0.R`. It does not install dependencies automatically.

## Mandatory local R gates

Before runtime release acceptance, execute the detailed protocol in `LOCAL_VALIDATION_GUIDE_1.0.0.md`. At minimum:

1. verify the frozen archive and internal source checksums;
2. preserve an immutable copy of the frozen source;
3. regenerate roxygen documentation in a working copy and audit changes;
4. run the complete non-Bayesian `testthat` suite;
5. render all 31 vignettes;
6. run the optional Bayesian tests when Bayesian release claims are required;
7. run the documented numerical known-truth controls;
8. execute `R CMD build agriGrowthFlow`;
9. record the SHA-256 of the resulting `agriGrowthFlow_1.0.0.tar.gz`;
10. execute `R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz` on that exact tarball;
11. inspect `00check.log`, install the checked tarball into a clean library, and perform installed-package smoke tests.

## Release status

The artifacts produced in this environment are **cryptographically frozen source snapshots**. They document a source tree that passed the package-specific static battery with zero failures. They do not substitute for R-native build and runtime validation.
