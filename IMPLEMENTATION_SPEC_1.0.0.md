# agriGrowthFlow 1.0.0 Consolidated Release: Implementation Specification

## 1. Release objective

Version 1.0.0 consolidates the complete scientific architecture developed in versions 0.1.0 through 0.5.0 into a stable public release. The release does not introduce a new plant-growth theory. Its main additions are orchestration, auditability, standardized result extraction, reproducible reporting, export, API stabilization, documentation consolidation, and release engineering.

The scientific rule remains unchanged: the persistent experimental unit and sampling mechanism must be defined before a growth trajectory is interpreted.

## 2. Stable scientific layers

### Foundations

Data roles, design validation, classical growth indices, biomass partitioning, allometry, and initial visualization remain the basis of the package.

### Parametric growth

The stable parametric registry includes Logistic, Gompertz, Richards, Chapman-Richards, Weibull, von Bertalanffy, beta growth, and expolinear models, with guarded starting values, multistart fitting, prediction, comparison, diagnostics, and derived biological traits.

### Longitudinal and flexible growth

Repeated-measurement analysis retains mixed-effects modeling, explicit AR(1)/CAR(1) residual correlation, variance structures, smoothing splines, LOESS, GAM/SCAM trajectories, numerical derivatives, FPCA, and experimental-unit growth-component MANOVA.

### Uncertainty

The stable uncertainty layer retains design-aware bootstrap methods, bootstrap trait intervals, model-selection stability, Bayesian Logistic/Gompertz/Richards hierarchy, prior and posterior predictive checks, MCMC diagnostics, posterior traits, PSIS-LOO, and predictive model weighting.

### Biological events and decisions

The 0.5.0 event layer remains stable: ordered multiphase logistic trajectories, fourth-derivative stability points, exploratory changepoints, measured disturbance and defoliation analysis, compensatory growth, density and neighborhood competition, coupled logistic competition simulation, thresholds, plateaus, conditional harvest optimization, observation schedules, design simulation, and trait-level Monte Carlo power.

## 3. New 1.0.0 public functions

### `growth_method_guide()`

**Purpose:** produce a transparent shortlist of analysis families from the declared design, time support, scientific objective, and optional backend availability.

**Signature:** see `inst/metadata/api_contract_1.0.0.csv`.

**Inputs:** `agri_growth_data` or data frame, optional role columns, objective, backend reporting flag.

**Output:** `agri_growth_method_guide`, a data frame with method, suitability, priority, backend, backend availability, rationale, and minimum requirement.

**Safeguards:** priority is a navigation rule, not a model probability or scientific proof. No p-value, R-squared, AIC, or AICc is used as a universal selection rule.

### `growth_workflow()`

**Purpose:** connect validation, method guidance, one explicit core strategy, diagnostics, candidate comparison, biological traits, and an optional uncertainty layer in one auditable object.

**Strategies:** `auto`, `classical`, `parametric`, `mixed`, `smooth`, `multiphase`.

**Objectives:** `trajectory`, `rates`, `treatment_comparison`, `uncertainty`, `phases`, `decision`.

**Uncertainty options:** `none`, `auto`, `bootstrap`, `bayesian`. Optional uncertainty-specific arguments are isolated in `uncertainty_args`, preventing arguments intended for the core model from being forwarded accidentally to bootstrap or Bayesian engines.

**Output:** `agri_growth_workflow` containing the original input, role metadata, validation, plan, guide, decision ledger, selected strategy, core analysis, diagnostics, candidate comparison, traits, uncertainty object, notes, seed, and execution flag.

**Planning-only mode:** `execute = FALSE` records the complete analysis contract without fitting a model.

**Automatic strategy rules:**

- classical analysis is prioritized for explicit interval-rate objectives when biological roles are declared;
- multiphase analysis is prioritized only for explicit phase objectives and sufficient temporal support;
- repeated-measurement treatment comparisons may prioritize mixed models when a persistent unit is declared and `nlme` is available;
- parametric analysis is otherwise the preferred automatic core for supported trajectory objectives with adequate time support;
- smoothing remains a transparent alternative for flexible shape analysis.

**Safeguards:** automatic mode does not assert that the selected method is uniquely correct. Grouped candidate comparisons are performed only within identical prepared observations. Automatic bootstrap is not silently attached across grouped fit collections.

### `growth_workflow_audit()`

**Purpose:** expose release-level gates as PASS, INFO, or FAIL records.

**Checks:** declared design validation when available, selected strategy, execution status, core object presence, generic diagnostics presence, candidate comparison, uncertainty object, seed, and workflow notes.

### `growth_table()`

**Purpose:** return standardized data-frame views of supported objects without exposing users to every internal list structure.

**Supported release views:** workflow audit, traits, candidate comparison, guide, parametric coefficients, classical intervals, validation issues, common diagnostics, smooth traits, bootstrap traits, and Bayesian diagnostic summaries.

**Safeguard:** nested statistical objects are not flattened when doing so would discard essential structure.

### `growth_report()`

**Purpose:** create a concise Markdown analysis record.

**Contents:** release version, analysis contract, workflow audit, candidate comparison when present, biological traits when present, workflow notes, and interpretation safeguards.

**Safeguard:** the report does not generate unsupported publication claims or automatic treatment-effect prose.

### `growth_export()`

**Formats:** `rds`, `csv`, and `bundle`.

**RDS:** preserves the complete object.

**CSV:** writes a standardized table only.

**Bundle:** writes the full RDS object, audit CSV, method-guide CSV, optional traits/comparison CSV files, and Markdown report.

**Safeguard:** RDS is documented as the preferred complete archive because CSV cannot represent nested model structures.

## 4. Public API contract

The stable release contains 75 exported functions. Their signatures, source files, scientific modules, and stability labels are stored in `inst/metadata/api_contract_1.0.0.csv`.

All 75 exports are labeled `stable-1.0.0` for the consolidated release. Future breaking changes should therefore require a major-version decision or an explicit deprecation cycle.

## 5. S3 contract

The release registers 41 S3 methods. Version 1.0.0 adds:

- `print.agri_growth_method_guide()`;
- `print.agri_growth_workflow()`;
- `summary.agri_growth_workflow()`.

Existing print, plot, coefficient, and data-frame methods remain unchanged.

## 6. Documentation contract

The package contains 31 extensive English vignettes.

Release-specific vignettes are:

- `v28-release-workflow-contract.Rmd`;
- `v29-reporting-audit-export.Rmd`;
- `v30-foundations-to-release-tutorial.Rmd`.

The integrated `v30` tutorial is the stable-release entry point and connects all previous modules while preserving links to the specialist vignettes.

## 7. Reference contract

The release inherits the 25 scientific references already double-verified in versions 0.1.0 through 0.5.0. No new statistical method was introduced solely for orchestration, reporting, or export, so no new scientific citation was required for those software functions.

`inst/metadata/reference_verification.csv` remains the machine-readable source of the two-source metadata audit. Every record must retain a MATCH status and two distinct verification sources.

## 8. Teaching-data contract

The ten frozen simulated datasets remain unchanged:

- `maize_destructive`;
- `bean_repeated`;
- `soybean_partition`;
- `sunflower_sigmoid`;
- `wheat_expolinear`;
- `soybean_irregular`;
- `coffee_diphasic`;
- `bean_defoliation`;
- `maize_density`;
- `tree_competition`.

All are teaching data and must not be presented as field evidence. Their SHA-256 values remain recorded in `inst/metadata/teaching_data_checksums.sha256`.

## 9. Test contract

Version 1.0.0 adds `tests/testthat/test-consolidated-release.R` covering:

- design-aware method guidance;
- planning-only workflow behavior;
- executed parametric workflow structure;
- standardized table extraction;
- Markdown report generation;
- RDS, CSV, and bundle export.

All previous numerical and scientific-regression tests remain part of the suite.

## 10. Example contract

`inst/examples/API_EXAMPLES_1.0.0.R` contains at least three call patterns for every exported function. The examples emphasize different design structures rather than superficial argument permutations.

## 11. Release metadata

`DESCRIPTION`, `NEWS.md`, `README.md`, and `inst/CITATION` identify version 1.0.0. `README.md` directs users to the consolidated workflow while preserving the specialist modules.

## 12. Static validation

The stable release static validator must check, at minimum:

- package metadata and version;
- public export count and uniqueness;
- source definitions for every export;
- S3 registrations and definitions;
- R delimiter balance;
- `.Rd` aliases and uniqueness;
- release manual coverage;
- 31-vignette presence and instructional depth;
- bibliography-key resolution and lack of unused keys;
- 25-reference double-verification ledger;
- ten teaching datasets and their checksums;
- API contract coverage;
- three examples for every public function;
- release-specific tests;
- source hygiene and absence of automatic dependency installation;
- release-specific scientific safeguards.

Static validation cannot substitute for R runtime validation.

## 13. Mandatory local runtime validation

On a system with R:

```r
roxygen2::roxygenise("agriGrowthFlow")
devtools::test("agriGrowthFlow")
devtools::build_vignettes("agriGrowthFlow")
```

Then:

```text
R CMD build agriGrowthFlow
R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz
```

Optional Bayesian tests require `brms`, `posterior`, `loo`, an available Stan backend, and the explicit test environment gate documented by the package.

## 14. Release freeze

The environment used for this implementation does not contain R. The deliverable produced here is therefore a frozen source snapshot, not a tarball generated by `R CMD build`.

The final source snapshot must include:

- `FREEZE_MANIFEST_1.0.0.md`;
- `LOCAL_VALIDATION_1.0.0.md`;
- `NAMESPACE_RD_SYNC_1.0.0.md`;
- `REFERENCE_AUDIT_1.0.0.md`;
- `TREE_1.0.0.txt`;
- `SHA256SUMS_1.0.0.txt`;
- archive-level SHA-256 values;
- independent extraction comparison of ZIP and TAR.GZ trees.

The snapshot may be called source-frozen only after the complete static battery reports zero failures and both archive formats independently reproduce the checksum-verified tree.
