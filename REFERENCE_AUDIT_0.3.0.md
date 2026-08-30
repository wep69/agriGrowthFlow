# agriGrowthFlow 0.3.0: Two-Source Reference Audit

**Audit date:** 2026-08-27

## Purpose

Version 0.3.0 adds longitudinal mixed-effects analysis, flexible smoothing, shape-constrained additive trajectories, functional principal component analysis, and multivariate growth-curve decomposition. These capabilities depend on statistical frameworks whose terminology, data structure, and interpretation must be represented precisely. Bibliographic metadata were therefore checked separately from methodological use.

The machine-readable audit is maintained in `inst/metadata/reference_verification.csv`. Version 0.3.0 retains every verified 0.1.0 and 0.2.0 record and adds the five core sources below.

## New core references

### Pinheiro & Bates (2000)

**Reference:** Pinheiro, J. C.; Bates, D. M. 2000. *Mixed-Effects Models in S and S-PLUS*. Springer, New York. DOI `10.1007/b98882`. Hardcover ISBN `978-0-387-98957-0`.

**Source 1:** Springer Nature Link bibliographic record.  
**Source 2:** Google Books bibliographic record.

**Result:** MATCH for title, authors, year, publisher context, 528-page extent, DOI, and hardcover ISBN.

**Use in package:** conceptual and computational basis for grouped-data, repeated-measures, linear and nonlinear mixed-effects modeling. Version 0.3.0 uses `nlme::lme()` only as an optional engine and exposes random effects, serial correlation, and residual variance structures explicitly.

### Mirman (2014)

**Reference:** Mirman, D. 2014. *Growth Curve Analysis and Visualization Using R*. CRC Press / Chapman & Hall, Boca Raton. Print ISBN `978-1-4665-8432-7`; electronic PDF ISBN `978-1-4665-8433-4`.

**Source 1:** Routledge/CRC Press publisher record for the first edition.  
**Source 2:** WorldCat bibliographic record for the 2014 electronic edition.

**Result:** MATCH for title, author, year, publisher, first-edition status, and 192-page extent. The publisher identifies the print edition by ISBN `9781466584327`; WorldCat confirms the 2014 CRC Press electronic edition and electronic ISBN `9781466584334`.

**Use in package:** pedagogical framework for multilevel polynomial growth-curve analysis, fixed and random time effects, and interpretation of longitudinal trajectories. The package applies these ideas to plants and experimental units rather than behavioral subjects.

### Pya & Wood (2015)

**Reference:** Pya, N.; Wood, S. N. 2015. Shape constrained additive models. *Statistics and Computing* 25:543-559. DOI `10.1007/s11222-013-9448-7`.

**Source 1:** Springer Nature article record.  
**Source 2:** University of Edinburgh Research Explorer.

**Result:** MATCH for title, authors, journal, volume, pages, DOI, early-online date, and 2015 issue publication.

**Use in package:** methodological basis for opt-in monotone additive growth curves. Version 0.3.0 does not impose monotonicity automatically because senescence, stress, defoliation, or measurement dynamics may legitimately create declines.

### Ramsay & Silverman (2005)

**Reference:** Ramsay, J. O.; Silverman, B. W. 2005. *Functional Data Analysis*, 2nd ed. Springer, New York. DOI `10.1007/b98888`. Hardcover ISBN `978-0-387-40080-8`.

**Source 1:** Springer Nature Link second-edition bibliographic record.  
**Source 2:** Google Books bibliographic record.

**Result:** MATCH for title, authors, second edition, year, publisher, DOI, and hardcover ISBN. Springer records XIX + 429 pages; Google Books reports 426 numbered content pages for one catalog representation. This pagination difference is a cataloging convention, not a metadata conflict relevant to citation identity.

**Use in package:** general functional-data framework and functional principal component analysis. The built-in grid engine uses an explicitly discretized, L2-scaled representation and does not claim to reproduce every smoothing or inferential method in the book.

### Wang, Chiou & Müller (2016)

**Reference:** Wang, J.-L.; Chiou, J.-M.; Müller, H.-G. 2016. Functional Data Analysis. *Annual Review of Statistics and Its Application* 3:257-295. DOI `10.1146/annurev-statistics-041715-033624`.

**Source 1:** Annual Reviews article record.  
**Source 2:** independent indexed scientific record cross-referencing the article metadata and DOI.

**Result:** MATCH for title, authors, year, journal, volume, pages, and DOI.

**Use in package:** modern overview of functional-data concepts and FPCA, including irregularly observed functional data. Version 0.3.0 therefore distinguishes the built-in common-support grid engine from optional sparse/irregular engines.

## Backend documentation checked during implementation

Backend API details were checked against current package documentation before freezing the source snapshot:

- `fdapace::FPCA()` accepts `methodSelectK = "FVE"`, `"AIC"`, `"BIC"`, or a positive integer; the implementation uses FVE selection when `npc` is omitted and a fixed positive integer when `npc` is supplied.
- `refund::fpca.sc()` accepts irregular long-form `ydata` with `.id`, `.index`, and `.value`, plus `pve` and optional `npc`; the implementation uses that contract directly.
- `nlme` remains optional and is checked with `requireNamespace()` before mixed-effects fitting.
- `mgcv`, `scam`, `fdapace`, and `refund` remain optional dependencies and are never installed automatically.

These backend documentation checks support implementation compatibility. They do not replace the bibliographic two-source audit above.

## Additional carried-forward multiphasic reference

### Mischan et al. (2015)

**Reference:** Mischan, M. M.; Passos, J. R. S.; Pinho, S. Z.; Carvalho, L. R. 2015. Inflection and stability points of diphasic logistic analysis of growth. *Scientia Agricola* 72(3):215-220. DOI `10.1590/0103-9016-2014-0212`.

**Source 1:** SciELO / *Scientia Agricola* article record.  
**Source 2:** supplied *Scientia Agricola* publisher PDF used in the project reference set.

**Result:** MATCH for title, authors, year, journal, volume, issue, pages, DOI, and the methodological statement that inflection and stability points of a diphasic logistic sum generally require numerical roots of derivatives of the complete sum.

**Use in package:** cited in the 0.2.0 tutorial only to define a scientifically important capability that remains deferred. No multiphasic fitting is claimed in 0.3.0.

## Earlier references retained

The ten records from versions 0.1.0 and 0.2.0 remain unchanged in the machine-readable audit. They cover classical growth analysis, experimental-unit treatment of growth curves, regression smoothers, defoliation-aware growth analysis, the Richards family, expolinear growth, corrected beta growth, and agricultural nonlinear regression.

## Audit outcome

The version 0.3.0 bibliography contains 16 audited core references, each represented in `inst/metadata/reference_verification.csv` with two named verification sources and a `MATCH` status. All citation keys used by the 18 package vignettes resolve to `vignettes/references.bib`. No author, title, DOI, ISBN, page range, or edition was invented to fill a missing field.
