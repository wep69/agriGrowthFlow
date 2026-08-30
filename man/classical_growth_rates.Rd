\name{classical_growth_rates}
\alias{classical_growth_rates}
\alias{growth_agr}
\alias{growth_rgr}
\alias{growth_nar}
\alias{growth_lar}
\alias{growth_sla}
\alias{growth_lmr}
\alias{growth_lai}
\alias{growth_cgr}
\title{Classical plant-growth rates and ratios}
\usage{
growth_agr(w1, w2, t1, t2)
growth_rgr(w1, w2, t1, t2)
growth_nar(w1, w2, a1, a2, t1, t2, tolerance = sqrt(.Machine$double.eps))
growth_lar(leaf_area, total_mass)
growth_sla(leaf_area, leaf_mass)
growth_lmr(leaf_mass, total_mass)
growth_lai(leaf_area, ground_area)
growth_cgr(w1, w2, t1, t2, ground_area = 1)
}
\arguments{
\item{w1,w2}{Beginning and ending dry mass.}
\item{t1,t2}{Beginning and ending time.}
\item{a1,a2}{Beginning and ending leaf area.}
\item{tolerance}{Numerical tolerance for the equal-leaf-area limit.}
\item{leaf_area}{Leaf area.}
\item{total_mass}{Total dry mass.}
\item{leaf_mass}{Leaf dry mass.}
\item{ground_area}{Represented ground area.}
}
\description{Vectorized foundational quantities for classical plant growth analysis. Inputs must use compatible physical units.}
\details{RGR and NAR require positive quantities where logarithms are used. When beginning and ending leaf areas are numerically equal, NAR uses the continuous limit AGR divided by leaf area.}
\references{Hunt R (1990). Basic Growth Analysis: Plant Growth Analysis for Beginners. doi:10.1007/978-94-010-9117-6.}
