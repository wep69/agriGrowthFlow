# Scientific reference metadata verification

**Package:** agriGrowthFlow 0.1.0  
**Verification date:** 2026-08-27

Scientific references used in the version 0.1.0 documentation were checked against at least two independent bibliographic or publisher records whenever practical. The detailed machine-readable record is distributed in `inst/metadata/reference_verification.csv`.

## Verification rule

A reference is marked `MATCH` only when the available records agree on the bibliographic elements needed by the package documentation: title, authorship, year, source, pagination when applicable, and DOI or ISBN when present.

The supplied PDFs were also used to verify scientific content and equations, but the two-source bibliographic audit was kept separate from content extraction. This separation prevents a locally supplied file name or OCR artifact from being treated as authoritative metadata.

## Core records

- **Hunt (1990):** Springer Nature Link and WorldCat agree on author, title, year and publication context. Springer confirms DOI `10.1007/978-94-010-9117-6`; the supplied book confirms the print ISBN and DOI.
- **Keuls & Garretsen (1982):** Springer Nature and Wageningen University & Research agree on title, authors, *Euphytica* 31, pages 51–64, and DOI `10.1007/BF00028306`.
- **Poorter (1989):** Wiley Online Library and a second indexed bibliographic record agree on title, author, *Physiologia Plantarum* 75(2), pages 237–244, and DOI `10.1111/j.1399-3054.1989.tb06175.x`.
- **Shipley & Hunt (1996):** Oxford Academic and ScienceDirect agree on title, authors, *Annals of Botany* 78(5), pages 569–576, and DOI `10.1006/anbo.1996.0162`.
- **Anten & Ackerly (2001):** Wiley Online Library and Wageningen University & Research agree on title, authors, *Functional Ecology* 15(6), pages 804–811, and DOI `10.1046/j.0269-8463.2001.00582.x`.

No DOI, author, pagination or publication year was inferred when the records disagreed. Any future disagreement must remain marked for manual verification rather than being silently reconciled.
