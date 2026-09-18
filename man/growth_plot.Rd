\name{growth_plot}
\alias{growth_plot}
\title{Plot plant-growth trajectories}
\usage{growth_plot(x, response = NULL, time = NULL, group = NULL, facet = NULL,
  summary = c("raw", "mean_se", "both"), log_y = FALSE, connect = NULL)}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{response}{Response column.}
\item{time}{Time or x-axis column.}
\item{group}{Grouping/color column.}
\item{facet}{Optional facet column.}
\item{summary}{Raw observations, mean with SE, or both.}
\item{log_y}{Use a logarithmic y scale.}
\item{connect}{Connect observations within a declared stable unit.}
}
\description{Creates an initial ggplot visualization while preserving raw observations and, when requested, within-unit trajectories.}

\examples{

## growth_plot()
# 1) Trajectories by treatment
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", treatment = "nitrogen",
                 total_mass = "total_mass_g")
growth_plot(g, response = "total_mass_g", group = "nitrogen")

# 2) Mean with standard error on a log scale
growth_plot(g, response = "total_mass_g", group = "nitrogen",
            summary = "mean_se", log_y = TRUE)

# 3) Faceted by block
growth_plot(g, response = "total_mass_g", group = "nitrogen", facet = "block")
}
