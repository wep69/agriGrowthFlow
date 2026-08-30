# Reference Audit for agriGrowthFlow 1.0.0

## Scope

Version 1.0.0 is a consolidated software release. It adds workflow orchestration, method guidance, audit trails, standardized table extraction, Markdown reporting, export, API stabilization, and release documentation. It does not introduce a new statistical growth method that requires an additional scientific citation.

The scientific basis of the release therefore remains the 25 references already audited across versions 0.1.0 through 0.5.0. Their machine-readable records are preserved in `inst/metadata/reference_verification.csv`.

## Double-verification rule

The release retains the same double-verification procedure used in the earlier versions.

Every reference used as part of the scientific basis must meet the following release checks:

1. two distinct verification sources are named;
2. the verification status begins with `MATCH`;
3. title, authorship, year, source, pagination when applicable, and DOI or ISBN agree to the level needed by the package documentation;
4. unresolved disagreement is not silently corrected by inference;
5. supplied PDFs may support scientific content, but bibliographic metadata verification remains a separate process.

## Stable reference ledger

The 1.0.0 ledger contains **25 rows** and all 25 remain marked MATCH. It includes the foundations and later methodological additions for:

- classical plant growth analysis;
- experimental-unit growth-curve analysis;
- synthesis of classical and functional growth analysis;
- regression smoothers and derivative estimation;
- periodic leaf-mass loss and iterative growth analysis;
- Richards and other nonlinear growth curves;
- crop-oriented expolinear and beta growth models;
- nonlinear regression in agronomy;
- mixed-effects longitudinal analysis;
- growth-curve analysis with multilevel models;
- shape-constrained smoothing;
- functional data analysis and FPCA;
- diphasic Logistic inflection and stability points;
- bootstrap methods;
- wild bootstrap context;
- nonlinear Bayesian modeling with brms;
- modern MCMC diagnostics;
- PSIS-LOO;
- predictive stacking;
- plantation competition theory;
- segmented regression context;
- general growth-curve modeling.

## Release-specific use of the references

The new orchestration layer cites or points users back to existing scientific methods rather than attributing the workflow machinery to a new external method.

### Design and classical analysis

Hunt (1990) and Keuls & Garretsen (1982) remain the primary conceptual references for classical plant-growth quantities and the persistent experimental-unit logic of growth curves.

### Parametric modeling

Richards (1959), Goudriaan & Monteith (1990), Yin et al. (2003) and its erratum, Archontoulis & Miguez (2015), and Panik (2014) continue to support the nonlinear growth layer.

### Longitudinal, flexible, and functional analysis

Pinheiro & Bates (2000), Mirman (2014), Pya & Wood (2015), Ramsay & Silverman (2005), Wang et al. (2016), and Shipley & Hunt (1996) support mixed, smoothing, derivative, shape-constrained, and functional workflows.

### Uncertainty

Davison & Hinkley (1997), Mammen (1992), Buerkner (2017), Vehtari et al. (2017, 2021), and Yao et al. (2018) support the bootstrap, Bayesian, MCMC-diagnostic, PSIS-LOO, and predictive-combination layers.

### Biological events and decisions

Mischan et al. (2015), Anten & Ackerly (2001), Gates (1982), Muggeo (2003), and Panik (2014) support the scientific context of multiphase growth, disturbance, competition, breakpoints, and broader growth-model decision questions.

## Source-derived versus package-specific release machinery

The following 1.0.0 functions are software orchestration developed specifically for agriGrowthFlow and are not presented as published statistical methods:

- `growth_method_guide()`;
- `growth_workflow()`;
- `growth_workflow_audit()`;
- `growth_table()`;
- `growth_report()`;
- `growth_export()`.

Their documentation explicitly preserves the assumptions and limitations of the scientific functions they call.

## Verification outcome

- Scientific reference rows: **25**.
- Records with two named distinct sources: **25/25**.
- Records marked MATCH: **25/25**.
- New unverifiable DOI, ISBN, author, title, year, pagination, or publisher metadata introduced by 1.0.0: **0**.

No bibliographic metadata was invented for the consolidated release.
