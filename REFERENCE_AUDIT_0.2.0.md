# agriGrowthFlow 0.2.0: Two-Source Reference Audit

**Audit date:** 2026-08-27

## Purpose

Version 0.2.0 introduces nonlinear growth equations whose parameterizations and biological landmarks depend on exact source equations. The audit therefore verifies bibliographic metadata separately from scientific content.

## New core references

### Richards (1959)

**Reference:** Richards, F. J. 1959. A Flexible Growth Function for Empirical Use. *Journal of Experimental Botany* 10(2):290-301. DOI `10.1093/jxb/10.2.290`.

**Source 1:** Oxford Academic article record.  
**Source 2:** CiNii Research bibliographic record.

**Result:** MATCH for title, author, year, journal, volume, issue, pages and DOI.

**Use in package:** historical and mathematical basis for the flexible Richards growth family.

### Goudriaan & Monteith (1990)

**Reference:** Goudriaan, J.; Monteith, J. L. 1990. A Mathematical Function for Crop Growth Based on Light Interception and Leaf Area Expansion. *Annals of Botany* 66(6):695-701. DOI `10.1093/oxfordjournals.aob.a088084`.

**Source 1:** Oxford Academic article record.  
**Source 2:** Wageningen University & Research publication record.

**Result:** MATCH for title, authors, year, journal, volume and pages; Oxford confirms issue and DOI.

**Use in package:** expolinear equation and interpretation of `Rm`, `Cm` and `tb`.

### Yin et al. (2003)

**Reference:** Yin, X.; Goudriaan, J.; Lantinga, E. A.; Vos, J.; Spiertz, H. J. 2003. A Flexible Sigmoid Function of Determinate Growth. *Annals of Botany* 91(3):361-371. DOI `10.1093/aob/mcg029`.

**Source 1:** Oxford Academic article record.  
**Source 2:** PubMed/PMC indexed record.

**Result:** MATCH for title, authors, year, journal, volume, issue, pages and DOI.

**Use in package:** beta growth model, final size `wmax`, time of maximum growth rate `tm`, and growth end time `te`.

### Yin et al. (2003) erratum

**Reference:** Erratum to A Flexible Sigmoid Function of Determinate Growth. *Annals of Botany* 91(6):753. DOI `10.1093/aob/mcg091`.

**Source 1:** Oxford Academic erratum record.  
**Source 2:** PubMed Central erratum record.

**Result:** MATCH. Both sources identify the correction to equation 11: the numerator in the exponent must be `te`, not `tm`.

**Implementation consequence:** `agriGrowthFlow` uses exponent `te/(te-tm)`. A regression test checks the corrected beta-growth endpoints.

### Archontoulis & Miguez (2015)

**Reference:** Archontoulis, S. V.; Miguez, F. E. 2015. Nonlinear Regression Models and Applications in Agricultural Research. *Agronomy Journal* 107(2):786-798. DOI `10.2134/agronj2012.0506`.

**Source 1:** Agronomy Journal publisher record.  
**Source 2:** independent indexed scientific reference record.

**Result:** MATCH for title, authors, year, journal, volume, issue, pages and DOI.

**Use in package:** nonlinear fitting workflow, attention to initialization, assumptions, parameter interpretation and agricultural applications.

## Foundation references

The five 0.1.0 references remain unchanged and retain their previous two-source audit. Their machine-readable records are included with the new rows in `inst/metadata/reference_verification.csv`.

## Audit outcome

All references included in the 0.2.0 core bibliography have a documented verification record. No author, DOI, pagination or equation correction was invented to fill a missing field.
