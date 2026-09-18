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

\examples{

## growth_data()
# 1) Full declaration of a destructive-harvest trial
d <- growth_example_data("maize_destructive")
g <- growth_data(
  d, time = "day", sampling = "destructive",
  experimental_unit = "plot_id", treatment = "nitrogen", block = "block",
  total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
  leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2"
)
g

# 2) Repeated measurements on the same plant
b <- growth_example_data("bean_repeated")
gb <- growth_data(
  b, time = "day", sampling = "repeated",
  experimental_unit = "plant_id", treatment = "water_regime",
  block = "block"
)
gb$sampling

# 3) Minimal declaration and a missing-column error
g2 <- growth_data(d, time = "day", sampling = "destructive",
                  experimental_unit = "plot_id", total_mass = "total_mass_g")
g2$roles$time
try(growth_data(d, time = "dia", experimental_unit = "plot_id"))

## growth_example_data()
# 1) Dimensions of one teaching dataset
d <- growth_example_data("maize_destructive")
dim(d)

# 2) Columns of another dataset
names(growth_example_data("coffee_diphasic"))

# 3) Two more accepted names
growth_example_data("bean_repeated")
length(unique(growth_example_data("maize_density")$nitrogen))

## as.data.frame.agri_growth_data()
# 1) Recover the original data frame
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
z <- as.data.frame(g)
class(z)

# 2) Dimensions and names preserved
dim(z)
names(z)[1:4]

# 3) Use the frame with ordinary functions
head(z, 3)

## print.agri_growth_data()
# 1) Readable summary of the object
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
print(g)

# 2) The return is the object itself, invisibly
x <- print(g)
identical(x, g)

# 3) Internal structure
str(g, max.level = 1)
}
