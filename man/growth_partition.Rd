\name{growth_partition}
\alias{growth_partition}
\title{Biomass partitioning with closure checks}
\usage{growth_partition(data, total_mass = NULL, components = NULL,
  normalize = FALSE, tolerance = 0.02, prefix = "frac_")}
\arguments{
\item{data}{Data frame or \code{agri_growth_data} object.}
\item{total_mass}{Total mass column.}
\item{components}{Component-mass columns.}
\item{normalize}{Normalize by the supplied component sum rather than total mass.}
\item{tolerance}{Closure tolerance.}
\item{prefix}{Fraction-column prefix.}
}
\description{Calculates biomass fractions while retaining component closure and unallocated biomass. Fractions are not silently renormalized by default.}

\examples{

## growth_partition()
# 1) Components detected from the declared object
d <- growth_example_data("soybean_partition")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g",
                 leaf_mass = "leaf_mass_g", root_mass = "root_mass_g",
                 stem_mass = "stem_mass_g",
                 reproductive_mass = "reproductive_mass_g")
pt <- growth_partition(g)
head(pt[, c("frac_leaf_mass_g", "closure", "closure_ok")])

# 2) Components declared on a raw data frame
pt2 <- growth_partition(d, total_mass = "total_mass_g",
                        components = c("leaf_mass_g", "stem_mass_g", "root_mass_g"))
sum(!pt2$closure_ok)

# 3) Normalization and prefix
names(growth_partition(g, normalize = TRUE, prefix = "p_"))[1:4]

## print.agri_growth_partition()
# 1) Partition summary
d <- growth_example_data("soybean_partition")
pt <- growth_partition(d, total_mass = "total_mass_g",
                       components = c("leaf_mass_g", "stem_mass_g"))
print(pt)

# 2) Stored attributes
attr(pt, "components")
attr(pt, "tolerance")

# 3) Invisible return
identical(print(pt), pt)
}
