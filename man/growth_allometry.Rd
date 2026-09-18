\name{growth_allometry}
\alias{growth_allometry}
\title{Log-log allometric analysis}
\usage{growth_allometry(data, x, y, group = NULL, level = 0.95)}
\arguments{
\item{data}{Data frame.}
\item{x,y}{Positive numeric variable names.}
\item{group}{Optional grouping column.}
\item{level}{Confidence level for the allometric exponent.}
}
\description{Fits log(y) = log(a) + k log(x) by ordinary least squares and returns the allometric coefficient, interval and fit summaries. OLS is directional and is not equivalent to standardized major-axis regression.}

\examples{

## growth_allometry()
# 1) Single log-log fit
d <- growth_example_data("soybean_partition")
growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g")$summary

# 2) One fit per group
growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g",
                 group = "cultivar")$summary

# 3) Different confidence level
growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g",
                 level = 0.90)$summary[, c("k", "k_low", "k_high")]

## print.agri_growth_allometry()
# 1) Summary of the fit
d <- growth_example_data("soybean_partition")
al <- growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g")
print(al)

# 2) Coefficient table
al$summary[, c("n", "a", "k", "r_squared")]

# 3) Invisible return
identical(print(al), al)
}
