\name{growth_data}
\alias{growth_data}
\alias{growth_example_data}
\title{Declare and load plant-growth data}
\usage{
growth_data(data, time, sampling = c("auto", "repeated", "destructive", "mixed"),
  experimental_unit = NULL, plant = NULL, plot = NULL, block = NULL,
  treatment = NULL, total_mass = NULL, leaf_area = NULL, leaf_mass = NULL,
  root_mass = NULL, stem_mass = NULL, reproductive_mass = NULL,
  ground_area = NULL, units = list(), metadata = list())

growth_example_data(name = c("maize_destructive", "bean_repeated", "soybean_partition", "sunflower_sigmoid", "wheat_expolinear", "soybean_irregular", "coffee_diphasic", "bean_defoliation", "maize_density", "tree_competition"))
}
\arguments{
\item{data}{A data frame.}
\item{time}{Name of the time column.}
\item{sampling}{Sampling mechanism.}
\item{experimental_unit,plant,plot,block,treatment}{Optional design-role column names.}
\item{total_mass,leaf_area,leaf_mass,root_mass,stem_mass,reproductive_mass,ground_area}{Optional biological measurement-role column names.}
\item{units}{Named list of physical units.}
\item{metadata}{Named list of contextual metadata.}
\item{name}{Frozen simulated teaching dataset name.}
}
\description{Records biological and experimental roles without altering observations. Teaching datasets are simulated and are distributed for examples and testing, not as empirical evidence.}
\value{\code{growth_data()} returns an object of class \code{agri_growth_data}. \code{growth_example_data()} returns a data frame.}
