\name{growth_predict}
\alias{growth_predict}
\alias{growth_compare}
\alias{growth_diagnose}
\title{Predict, compare, and diagnose parametric growth models}
\usage{
growth_predict(object, time = NULL,
  interval = c("none", "confidence", "prediction"), level = 0.95)

growth_compare(...)

growth_diagnose(object, boundary_fraction = 0.01)
}
\arguments{
\item{object}{A parametric growth fit, fit set, or grouped fit collection as appropriate.}
\item{time}{Optional numeric prediction times.}
\item{interval}{Point predictions, confidence intervals, or prediction intervals.}
\item{level}{Interval confidence level.}
\item{...}{Parametric fits or one candidate fit set.}
\item{boundary_fraction}{Fraction of a hard-bound span used to flag near-bound coefficients.}
}
\description{Produces fitted trajectories and local delta-method intervals, refuses information-criterion comparison across different prepared observations, and summarizes residual, convergence, boundary, conditioning, and within-unit lag diagnostics.}
\value{Data frames or an \code{agri_growth_diagnostics} object, depending on the function.}

\examples{

## growth_predict()
# 1) Prediction on the observed grid
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
head(growth_predict(f))

# 2) Confidence interval
growth_predict(f, time = c(20, 40, 60), interval = "confidence", level = 0.90)

# 3) Prediction interval
growth_predict(f, time = c(20, 40, 60), interval = "prediction")

## growth_compare()
# 1) Two models on the same prepared observations
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f1 <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
f2 <- growth_fit(d1, "gompertz", time = "day", response = "biomass_g")
growth_compare(f1, f2)[, c("model", "aicc", "delta_aicc", "akaike_weight")]

# 2) Three models
f3 <- growth_fit(d1, "richards", time = "day", response = "biomass_g")
growth_compare(f1, f2, f3)$model

# 3) Comparison inside a collection by group
fc <- growth_fit(d, c("logistic", "gompertz"), time = "day",
                 response = "biomass_g", group = "cultivar")
growth_compare(fc$fits[[1]]$fits[[1]], fc$fits[[1]]$fits[[2]])

## growth_diagnose()
# 1) Default diagnostics
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
dg <- growth_diagnose(f)
dg$summary[, c("model", "rmse", "descriptive_r_squared")]

# 2) Distance to bounds with a looser criterion
growth_diagnose(f, boundary_fraction = 0.2)$boundaries

# 3) Detected issue codes
growth_diagnose(f)$issues$code

## print.agri_growth_comparison()
# 1) Comparison table
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f1 <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
f2 <- growth_fit(d1, "gompertz", time = "day", response = "biomass_g")
cmp <- growth_compare(f1, f2)
print(cmp)

# 2) Best model by AICc
cmp$model[which.min(cmp$aicc)]

# 3) Invisible return
identical(print(cmp), cmp)

## plot.agri_growth_fit()
# 1) Fitted curve over the data
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
p <- plot(f)
class(p)[1]

# 2) With a confidence band
class(plot(f, interval = "confidence", level = 0.90, n = 50))[1]

# 3) The returned object is an editable ggplot
p + ggplot2::labs(title = "Fitted curve")

## print.agri_growth_diagnostics()
# 1) Diagnostic summary
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
print(growth_diagnose(f))

# 2) Residual table
head(growth_diagnose(f)$residuals, 3)

# 3) Invisible return
dg <- growth_diagnose(f)
identical(print(dg), dg)
}
