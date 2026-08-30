# Reference Audit for agriGrowthFlow 0.4.0

## Scope

Version 0.4.0 adds uncertainty quantification by bootstrap and Bayesian nonlinear hierarchical modeling. The package-level metadata table now contains 22 core references, each with two independent verification sources recorded in `inst/metadata/reference_verification.csv`.

## Newly audited references

### Davison & Hinkley (1997)

**Reference:** Davison AC, Hinkley DV. *Bootstrap Methods and Their Application*. Cambridge University Press, 1997. DOI 10.1017/CBO9780511802843.

**Verification 1:** Cambridge University Press book record confirms authors, title, original print year, publisher, ISBNs, and DOI.

**Verification 2:** Cambridge Core chapter/frontmatter metadata independently reproduces the book title, authors, publisher, print year, and book DOI.

**Use in 0.4.0:** general bootstrap framework, confidence intervals, hierarchical resampling, and explicit treatment of complex dependence.

### Mammen (1992)

**Reference:** Mammen E. *When Does Bootstrap Work? Asymptotic Results and Simulations*. Lecture Notes in Statistics 77. Springer, 1992. DOI 10.1007/978-1-4612-2950-6.

**Verification 1:** Springer Nature bibliographic record.

**Verification 2:** Google Books bibliographic record.

**Use in 0.4.0:** wild-bootstrap multiplier option and methodological background.

### Bürkner (2017)

**Reference:** Bürkner P-C. brms: An R Package for Bayesian Multilevel Models Using Stan. *Journal of Statistical Software* 80(1):1-28. DOI 10.18637/jss.v080.i01.

**Verification 1:** Journal of Statistical Software article record confirms author, title, date, volume, issue, pages, and DOI.

**Verification 2:** Journal of Statistical Software citation metadata independently reports the same bibliographic fields. Current official brms documentation was additionally checked for nonlinear formula and nonlinear-prior syntax.

**Use in 0.4.0:** optional Bayesian nonlinear multilevel backend and nonlinear-parameter prior specification.

### Vehtari, Gelman & Gabry (2017)

**Reference:** Vehtari A, Gelman A, Gabry J. Practical Bayesian model evaluation using leave-one-out cross-validation and WAIC. *Statistics and Computing* 27:1413-1432. DOI 10.1007/s11222-016-9696-4.

**Verification 1:** Springer journal record and indexed Springer references confirm title, authors, journal, volume, pages, and DOI.

**Verification 2:** arXiv record confirms title and authors and documents PSIS-LOO computation. The current official loo documentation was additionally checked for model-weighting behavior.

**Use in 0.4.0:** PSIS-LOO and Pareto-k diagnostic workflow.

### Vehtari et al. (2021)

**Reference:** Vehtari A, Gelman A, Simpson D, Carpenter B, Bürkner P-C. Rank-Normalization, Folding, and Localization: An Improved R-hat for Assessing Convergence of MCMC. *Bayesian Analysis* 16(2):667-718. DOI 10.1214/20-BA1221.

**Verification 1:** Project Euclid/Bayesian Analysis bibliographic metadata.

**Verification 2:** arXiv record confirms title and author list and describes the rank-normalized diagnostic.

**Use in 0.4.0:** R-hat and effective-sample-size diagnostic interpretation.

### Yao et al. (2018)

**Reference:** Yao Y, Vehtari A, Simpson D, Gelman A. Using Stacking to Average Bayesian Predictive Distributions. *Bayesian Analysis* 13(3):917-1007. DOI 10.1214/17-BA1091.

**Verification 1:** Project Euclid/Bayesian Analysis bibliographic record.

**Verification 2:** arXiv record confirms title, authors, and stacking methodology. The official loo documentation was additionally checked for stacking and pseudo-BMA+ implementation details.

**Use in 0.4.0:** predictive stacking and pseudo-BMA+ model weighting.

## Verification status

All 22 rows in `inst/metadata/reference_verification.csv` are marked MATCH and name two distinct sources. No author, title, DOI, ISBN, journal, volume, issue, or page metadata was invented.

## Software documentation checked in 2026

The implementation was cross-checked against current official documentation for `brms` nonlinear formulas and priors and `loo` model weighting. These software pages are implementation references and do not replace the primary methodological citations above.
