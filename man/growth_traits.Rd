\name{growth_traits}
\alias{growth_traits}
\alias{growth_inflection}
\alias{growth_maxrate}
\alias{growth_time_to}
\title{Extract biologically interpretable traits from growth curves}
\usage{
growth_traits(object)

growth_inflection(object)

growth_maxrate(object)

growth_time_to(object, fraction = NULL, target = NULL)
}
\arguments{
\item{object}{A parametric growth fit, candidate fit set, or grouped fit collection.}
\item{fraction}{Optional fractions of a finite upper level.}
\item{target}{Optional absolute response targets.}
}
\description{Translates model-specific coefficients into common growth landmarks including inflection, maximum absolute rate, t10, t50, t90, and area under the fitted trajectory over observed time support.}
\value{A data frame.}
