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

\examples{

## growth_agr()
# 1) One interval
growth_agr(w1 = 10, w2 = 25, t1 = 14, t2 = 28)

# 2) Several intervals at once
growth_agr(c(10, 25, 60), c(25, 60, 110), c(14, 28, 42), c(28, 42, 56))

# 3) Columns of a data frame
d <- data.frame(w1 = c(5, 8), w2 = c(9, 20), t1 = c(0, 7), t2 = c(7, 14))
with(d, growth_agr(w1, w2, t1, t2))

## growth_rgr()
# 1) One interval
growth_rgr(w1 = 10, w2 = 25, t1 = 14, t2 = 28)

# 2) A mass loss gives a negative rate
growth_rgr(w1 = 25, w2 = 10, t1 = 14, t2 = 28)

# 3) Vectorized
growth_rgr(c(10, 25), c(25, 60), c(14, 28), c(28, 42))

## growth_nar()
# 1) One interval with unequal leaf areas
growth_nar(w1 = 10, w2 = 25, a1 = 2, a2 = 5, t1 = 14, t2 = 28)

# 2) Equal areas use the continuous limit
growth_nar(w1 = 10, w2 = 25, a1 = 3, a2 = 3, t1 = 14, t2 = 28)

# 3) Tolerance for near-equality
growth_nar(10, 25, 3, 3 + 1e-10, 14, 28, tolerance = 1e-6)

## growth_lar()
# 1) Leaf area ratio
growth_lar(leaf_area = 0.5, total_mass = 25)

# 2) Vectorized
growth_lar(c(0.5, 0.9), c(25, 40))

# 3) Columns of a data frame
d <- data.frame(area = c(0.5, 0.9), mass = c(25, 40))
with(d, growth_lar(area, mass))

## growth_sla()
# 1) Specific leaf area
growth_sla(leaf_area = 0.5, leaf_mass = 10)

# 2) Vectorized
growth_sla(c(0.5, 0.8), c(10, 12))

# 3) Invalid input
try(growth_sla(leaf_area = -0.5, leaf_mass = 10))

## growth_lmr()
# 1) Leaf mass ratio
growth_lmr(leaf_mass = 10, total_mass = 25)

# 2) Vectorized
growth_lmr(c(10, 18), c(25, 40))

# 3) The identity LAR = SLA x LMR
sla <- growth_sla(leaf_area = 0.5, leaf_mass = 10)
lmr <- growth_lmr(leaf_mass = 10, total_mass = 25)
c(sla = sla, lmr = lmr, product = sla * lmr, lar = growth_lar(0.5, 25))

## growth_lai()
# 1) Leaf area index
growth_lai(leaf_area = 0.5, ground_area = 0.25)

# 2) Vectorized
growth_lai(c(0.5, 1.0, 2.0), ground_area = 0.25)

# 3) Invalid ground area
try(growth_lai(leaf_area = 0.5, ground_area = 0))

## growth_cgr()
# 1) Unit ground area
growth_cgr(10, 25, 14, 28)

# 2) Declared ground area
growth_cgr(10, 25, 14, 28, ground_area = 0.25)

# 3) Vectorized
growth_cgr(c(10, 25), c(25, 60), c(14, 28), c(28, 42), ground_area = 0.5)
}
