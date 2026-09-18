\name{disturbance_growth}
\alias{growth_event}
\alias{growth_defoliation}
\alias{growth_compensation}
\title{Known disturbances, iterative defoliation analysis, and compensatory growth}
\usage{
growth_event(data, time, response, event_time, unit = NULL,
  event_type = "disturbance", event_amount = NULL)

growth_defoliation(data, time, total_mass, leaf_mass, leaf_area,
  total_loss = NULL, leaf_mass_loss = NULL, leaf_area_loss = NULL,
  unit = NULL, step = 0.25)

growth_compensation(data, group, control, response, time = NULL,
  unit = NULL, metric = c("final", "auc", "slope"))
}
\arguments{
\item{data}{A data frame or, for \code{growth_compensation()}, an \code{agri_growth_event}.}
\item{time,response}{Time and response column names.}
\item{event_time}{Known event time.}
\item{unit}{Optional persistent experimental-unit column.}
\item{event_type}{Descriptive event label.}
\item{event_amount}{Optional known amount removed or applied.}
\item{total_mass,leaf_mass,leaf_area}{Measured plant-state columns.}
\item{total_loss,leaf_mass_loss,leaf_area_loss}{Measured loss columns. Missing columns imply zero loss.}
\item{step}{Numerical integration step.}
\item{group}{Treatment or disturbance grouping column.}
\item{control}{Value identifying the control group.}
\item{metric}{Final response, area under the curve, or slope summary.}
}
\description{Declares known biological events, estimates an iterative defoliation model using measured mass and leaf-area losses, and summarizes compensatory responses relative to a control.}
\value{Structured event or defoliation objects, or a compensation summary data frame.}

\examples{

## growth_event()
# 1) A known event on a raw data frame
d <- growth_example_data("bean_defoliation")
ev <- growth_event(d, time = "day", response = "total_mass_g",
                   event_time = 30, unit = "plant_id")
class(ev)

# 2) The same event from the declared object
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "treatment",
                 total_mass = "total_mass_g")
growth_event(g, time = "day", response = "total_mass_g", event_time = 30)

# 3) Event type and amount
ev2 <- growth_event(d, time = "day", response = "total_mass_g",
                    event_time = 30, event_type = "defoliation",
                    event_amount = 0.5)
ev2$event_type

## growth_defoliation()
# 1) Defoliation with measured losses
d <- growth_example_data("bean_defoliation")
df <- growth_defoliation(d, time = "day", total_mass = "total_mass_g",
                         leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2",
                         total_loss = "total_loss_g",
                         leaf_mass_loss = "leaf_mass_loss_g",
                         leaf_area_loss = "leaf_area_loss_m2",
                         unit = "plant_id")
head(df$parameters)

# 2) From the declared object
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "treatment",
                 total_mass = "total_mass_g", leaf_mass = "leaf_mass_g",
                 leaf_area = "leaf_area_m2")
growth_defoliation(g, time = "day", total_mass = "total_mass_g",
                   leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2")

# 3) Smaller integration step
growth_defoliation(d, time = "day", total_mass = "total_mass_g",
                   leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2",
                   unit = "plant_id", step = 0.1)$parameters[1, 1:3]

## growth_compensation()
# 1) Compensation on the final response
d <- growth_example_data("bean_defoliation")
growth_compensation(d, group = "treatment", control = "control",
                    response = "total_mass_g", time = "day", unit = "plant_id")

# 2) Compensation on the area under the curve
growth_compensation(d, group = "treatment", control = "control",
                    response = "total_mass_g", time = "day", unit = "plant_id",
                    metric = "auc")

# 3) Compensation on the slope
growth_compensation(d, group = "treatment", control = "control",
                    response = "total_mass_g", time = "day", unit = "plant_id",
                    metric = "slope")

## print.agri_growth_event()
# 1) Event summary
d <- growth_example_data("bean_defoliation")
ev <- growth_event(d, time = "day", response = "total_mass_g", event_time = 30)
print(ev)

# 2) Columns created by the event
head(ev$data[, c("day", ".event_centered_time", ".post_event")])

# 3) Invisible return
identical(print(ev), ev)

## print.agri_growth_defoliation()
# 1) Defoliation summary
d <- growth_example_data("bean_defoliation")
df <- growth_defoliation(d, time = "day", total_mass = "total_mass_g",
                         leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2",
                         unit = "plant_id")
print(df)

# 2) Parameter table
head(df$parameters)

# 3) Invisible return
identical(print(df), df)
}
