# Reference Audit for agriGrowthFlow 0.5.0

## Scope

Version 0.5.0 adds biological events, multiphase growth, disturbance analysis, competition, observation planning, and conditional agronomic decision support. The package metadata table now contains 25 core references. Every row in `inst/metadata/reference_verification.csv` records two distinct verification sources and a MATCH status.

## References already verified in earlier releases and reused in 0.5.0

The 0.5.0 implementation continues to rely on the previously audited foundations of Hunt (1990), Keuls and Garretsen (1982), Anten and Ackerly (2001), Richards (1959), Shipley and Hunt (1996), and Mischan et al. (2015), among others. Their existing two-source verification records were retained unchanged.

### Mischan et al. (2015)

**Reference:** Mischan MM, Passos JRS, Pinho SZ, Carvalho LR. Inflection and stability points of diphasic logistic analysis of growth. *Scientia Agricola* 72(3):215-220. DOI 10.1590/0103-9016-2014-0212.

**Verification source 1:** Scientia Agricola / University of São Paulo journal record.

**Verification source 2:** SciELO article/PDF record.

**Use in 0.5.0:** distinction between critical points of separate logistic components and critical points of the complete diphasic sum, including numerical stability-point searches on the fourth derivative.

### Anten & Ackerly (2001)

**Reference:** Anten NPR, Ackerly DD. A new method of growth analysis for plants that experience periodic losses of leaf mass. *Functional Ecology* 15(6):804-811. DOI 10.1046/j.0269-8463.2001.00582.x.

**Verification source 1:** Wiley Online Library article record.

**Verification source 2:** Wageningen University & Research publication record.

**Use in 0.5.0:** iterative analysis of growth when biomass and leaf area are repeatedly lost, with losses treated as measured inputs rather than reconstructed from a smooth polynomial.

## Newly audited references for version 0.5.0

### Gates (1982)

**Reference:** Gates DJ. Analysis of Some Equations of Growth and Competition in Plantations. *Mathematical Biosciences* 59(1):17-32. DOI 10.1016/0025-5564(82)90106-7.

**Verification source 1:** ScienceDirect confirms title, author, journal, volume, issue, pages, year, and DOI.

**Verification source 2:** OpenAlex independently confirms the same DOI, author, journal, volume, issue, pages, and publication year.

**Use in 0.5.0:** theoretical motivation for coupled plant competition and the importance of spatial interactions. The package documentation explicitly states that `growth_competition()` is a generic coupled-logistic simulator and is not the exact zone-of-influence model analyzed by Gates.

### Muggeo (2003)

**Reference:** Muggeo VMR. Estimating regression models with unknown break-points. *Statistics in Medicine* 22(19):3055-3071. DOI 10.1002/sim.1545.

**Verification source 1:** Wiley Online Library confirms author, title, journal, volume, issue, pages, year, and DOI.

**Verification source 2:** PubMed independently confirms the title, author, journal citation, pages, year, PMID, and DOI.

**Use in 0.5.0:** methodological context for breakpoint and segmented-regression thinking. `growth_changepoint()` is intentionally documented as a simpler one-breakpoint continuous piecewise-linear grid search, not as a reimplementation of the full segmented-regression algorithm.

### Panik (2014)

**Reference:** Panik MJ. *Growth Curve Modeling: Theory and Applications*. John Wiley & Sons, 2014. ISBN 978-1-118-76404-6.

**Verification source 1:** Wiley-VCH book record confirms author, title, edition, publication date, publisher, page count context, and ISBN.

**Verification source 2:** International Statistical Review book review archived by the University of Michigan independently reports author, title, publisher/year context, and ISBN 978-1-118-76404-6.

**Use in 0.5.0:** broader growth-model, yield-density, and applied decision context.

## Verification status

The metadata table contains 25 rows. All 25 rows are marked MATCH and each identifies two distinct verification sources. No DOI, ISBN, page range, journal, title, or author field was invented for the new references.

## Source-derived versus package-specific methods

The literature supports the scientific ideas used in this release, but several exported functions are intentionally package-specific simplifications:

- `growth_multiphase()` fits ordered sums of logistic components, while the critical-point logic follows the complete-curve principle in Mischan et al. (2015).
- `growth_changepoint()` is an exploratory grid-search piecewise-linear model and is not the full algorithm in Muggeo (2003).
- `growth_defoliation()` follows the state-update structure of Anten and Ackerly (2001), but uses a numerical implementation with constant parameters over the analyzed window.
- `growth_neighbor()` is a transparent size-distance index defined in the package and is not attributed to Gates (1982).
- `growth_competition()` is a generic coupled logistic simulator and is not the Gates zone-of-influence system.
- `growth_schedule()` is a transparent rate-and-curvature heuristic and is not presented as D-optimal design.
- `growth_power()` is a trait-level Monte Carlo approximation and is not presented as power for a complete nonlinear mixed or Bayesian model.
