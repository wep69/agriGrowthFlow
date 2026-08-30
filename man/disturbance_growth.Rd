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
