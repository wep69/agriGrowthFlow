# agriGrowthFlow 0.3.0 Freeze Manifest

**Version:** 0.3.0  
**Freeze date:** 2026-08-27  
**Artifact type:** frozen source snapshot, not an `R CMD build` tarball

## Freeze decision

The 0.3.0 development tree is frozen after completion of the longitudinal, flexible, functional, and multivariate growth layer and after correction of the remaining source-synchronization issues found during freeze review.

The final static validation battery in the current environment reports **395 PASS and 0 FAIL**.

## Functional scope frozen in 0.3.0

The frozen tree contains the complete 0.1.0 and 0.2.0 APIs plus the following 0.3.0 capabilities:

- `growth_mixed()` and `growth_mixed_diagnose()` for polynomial mixed-effects growth analysis with persistent-unit random effects, explicit AR(1)/CAR(1) correlation choices, and residual variance structures;
- `growth_smooth()`, `growth_smooth_predict()`, `growth_derivative()`, `growth_acceleration()`, and `growth_smooth_traits()` for smoothing splines, LOESS, optional GAM/SCAM trajectories, derivatives, and descriptive landmarks;
- `growth_fpca()` and `growth_functional()` for built-in common-support L2-scaled FPCA and optional sparse/irregular functional-data engines;
- `growth_curve_coefficients()` and `growth_manova()` for orthogonal experimental-unit growth components and MANOVA on a common observed time grid;
- simulated irregular soybean phenotyping data for longitudinal and functional examples.

## Corrections completed during freeze review

- Updated the static validation battery from the 0.2.0 assumptions to the complete 0.3.0 API and data layer.
- Consolidated public examples in `inst/examples/API_EXAMPLES_0.3.0.R`, with at least three call patterns for every one of the 41 exported functions.
- Corrected the stale `growth_smooth()` `.Rd` usage so that `unit = NULL` matches the R source signature.
- Verified all 41 NAMESPACE exports against source definitions and manual aliases.
- Verified all 22 registered S3 methods against source definitions.
- Added `NAMESPACE_RD_SYNC_0.3.0.md` as a machine-derived synchronization audit.
- Removed ChatGPT UI citation artifacts from an earlier tutorial and replaced the scientific diphasic-growth statement with the formal `MischanEtAl2015` bibliography key.
- Added the corresponding audited Mischan et al. reference to `references.bib` and `reference_verification.csv`.
- Expanded the bibliographic audit to 16 core records, all with two named verification sources and MATCH status.
- Refreshed checksums for all six simulated teaching datasets, including `soybean_irregular.csv`.
- Updated `.Rbuildignore` so development validation, audit, synchronization, freeze, tree, and checksum files do not enter a future R-built source tarball.

## Frozen source counts

- Public exported functions: **41**.
- Registered S3 methods: **22**.
- R source files: **18**.
- Manual `.Rd` files: **16**.
- Test source files under `tests/testthat`: **11**.
- Extensive package vignettes: **18**.
- Simulated teaching datasets: **6**.
- Two-source audited bibliography records: **16**.

## Documentation frozen in this version

The 0.3.0 documentation adds six extensive English vignettes while preserving all earlier material:

- `v12-longitudinal-mixed-effects.Rmd`;
- `v13-flexible-smoothing-derivatives.Rmd`;
- `v14-shape-constrained-growth.Rmd`;
- `v15-functional-growth-fpca.Rmd`;
- `v16-multivariate-growth-manova.Rmd`;
- `v17-longitudinal-flexible-workflow.Rmd`.

The integrated `v17` tutorial contains more than 1,000 lines and connects experimental design, repeated dependence, smoothing, derivatives, FPCA, MANOVA, interpretation, and reporting.

## Validation status

`LOCAL_VALIDATION_0.3.0.md` records every static check and its result. The zero-failure static battery covers metadata, API definitions, S3 registration, delimiter balance, manual aliases, the corrected manual signature, vignette depth, bibliography resolution, two-source reference records, teaching-data hierarchy, retained mathematical identities, longitudinal safeguards, flexible-smoothing logic, FPCA support rules and backend contracts, MANOVA grid protection, test-source coverage, example coverage, source-tree hygiene, and teaching-data hashes.

## R runtime limitation

No R executable is installed in the current environment. Therefore this freeze does **not** claim execution of:

- `roxygen2` regeneration;
- `testthat` tests;
- vignette rendering;
- `R CMD build`;
- `R CMD check --as-cran`.

For this reason the ZIP and TAR.GZ artifacts are labeled **frozen source snapshots**. They are not represented as R-built release tarballs.

The required local commands and numerical controls are documented in `LOCAL_VALIDATION_0.3.0.md`.

## Integrity artifacts

The frozen delivery is accompanied by:

- `TREE_0.3.0.txt`, the source-tree listing;
- `SHA256SUMS_0.3.0.txt`, SHA-256 hashes for source files except the checksum file itself;
- `agriGrowthFlow_0.3.0_archive_checksums.sha256`, external SHA-256 hashes for the final ZIP and TAR.GZ snapshots;
- `ARCHIVE_VERIFICATION_0.3.0.md`, extraction and cross-format integrity results.

The archive checksum and extraction-verification files are external to the frozen package tree so that computing them does not alter the archived source they describe.

## Freeze rule

Any subsequent modification to R source, manuals, vignettes, tests, datasets, metadata, package documentation, or internal verification records constitutes a new development state and requires new source checksums and new snapshots.
