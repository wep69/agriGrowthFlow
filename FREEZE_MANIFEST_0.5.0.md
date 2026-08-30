# agriGrowthFlow 0.5.0 Freeze Manifest

## Freeze status

Version 0.5.0 is frozen as a source snapshot after source-level validation.

Static validation result: **542 PASS, 0 FAIL**.

This environment does not contain R. Therefore the frozen artifacts are source snapshots, not tarballs produced by `R CMD build`. Runtime validation with R remains mandatory before CRAN-like release use.

## Frozen scope

- Package version: 0.5.0
- Public functions: 69
- Registered S3 methods: 38
- R source files: 21
- Rd manual files: 23
- Vignettes: 28
- Frozen simulated teaching datasets: 10
- Double-verified reference records: 25
- Test source files: 14

## Version 0.5.0 additions

The 0.5.0 layer adds ordered multiphase logistic growth, diphasic convenience fitting, complete-curve stability points, exploratory changepoints, known-event declaration, iterative defoliation analysis with measured losses, compensatory-growth summaries, reciprocal size-density analysis, a transparent neighborhood index, generic coupled logistic competition, thresholds, practical plateau times, conditional harvest optimization, observation-schedule heuristics, design simulation, and trait-level Monte Carlo power.

Four new simulated teaching datasets are included: `coffee_diphasic`, `bean_defoliation`, `maize_density`, and `tree_competition`.

Five new extensive English vignettes are included, ending with `v27-biological-events-decisions-workflow.Rmd` as the integrated tutorial.

## Scientific boundaries retained in the frozen release

- Multiple logistic components are descriptive phases unless independent biology supports stronger labels.
- Stability points for multiphase growth are computed on the complete summed trajectory.
- Known disturbance times are declared as observed design information rather than re-estimated by default.
- Defoliation losses are measured inputs. The package does not invent removed biomass or leaf area.
- The neighborhood competition index is package-defined and transparent.
- The coupled logistic simulator is not labeled as the exact Gates zone-of-influence system.
- Observation schedules are heuristics, not D-optimal designs.
- Harvest optimization is conditional on the fitted curve and user-supplied economic assumptions.
- Trait-level power is a planning approximation, not power for a complete mixed or Bayesian model.

## Integrity files

`SHA256SUMS_0.5.0.txt` contains SHA-256 hashes for the frozen package-tree files except the checksum ledger itself and `TREE_0.5.0.txt`, which are the two integrity indexes. `TREE_0.5.0.txt` records all file names in the frozen tree, including both integrity indexes. Archive-level SHA-256 values are stored outside the archive in `agriGrowthFlow_0.5.0_archive_checksums.sha256` so that archive hashes do not create a self-reference problem.

## Mandatory local R gates

Before runtime release, execute the procedures in `LOCAL_VALIDATION_0.5.0.md`, including `roxygen2::roxygenise()`, the complete `testthat` suite, rendering all 28 vignettes, `R CMD build`, and `R CMD check --as-cran` on the exact built tarball. Optional Bayesian runtime tests require the corresponding Stan toolchain and optional dependencies.
