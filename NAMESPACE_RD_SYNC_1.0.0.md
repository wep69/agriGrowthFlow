# agriGrowthFlow 1.0.0: NAMESPACE and Rd Synchronization Audit

## Summary

- Exported functions: **75**.
- Registered S3 methods: **41**.
- R source files: **22**.
- Manual `.Rd` files: **24**.
- Exported functions without source definition: **0**.
- Exported functions without manual alias: **0**.
- Export aliases duplicated across manual files: **0**.
- Registered S3 methods without source definition: **0**.

## Release-specific API

- `growth_method_guide()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.
- `growth_workflow()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.
- `growth_workflow_audit()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.
- `growth_table()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.
- `growth_report()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.
- `growth_export()` is exported, defined in `R/consolidated-release.R`, and documented by `man/consolidated_release.Rd`.

## Stable API contract

`inst/metadata/api_contract_1.0.0.csv` contains one row for every exported function and records its source file, module, stable-release label, and frozen source signature.

## S3 additions

- `print.agri_growth_method_guide()`
- `print.agri_growth_workflow()`
- `summary.agri_growth_workflow()`

## Static result

All NAMESPACE definitions and manual aliases are synchronized at the source-snapshot level. No missing or duplicate exported aliases were detected.

## Mandatory runtime regeneration gate

This environment does not contain R. On the local validation machine, run:

```r
roxygen2::roxygenise("agriGrowthFlow")
```

Then compare the regenerated `NAMESPACE` and `man/` tree against this frozen source contract. Review any difference in exports, S3 registrations, signatures, aliases, usage blocks, or argument documentation before building the release tarball.

