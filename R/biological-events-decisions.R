
.agf_grid_n <- function(n, min_n = 101L, name = "n") {
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < min_n || abs(n - round(n)) > 1e-8) {
    stop("`", name, "` must be an integer of at least ", min_n, ".", call. = FALSE)
  }
  as.integer(n)
}

.agf_multiphase_unpack <- function(theta, n_phases) {
  if (!n_phases %in% 1:3) stop("`n_phases` must be 1, 2, or 3.", call. = FALSE)
  idx <- 1L
  amp <- scale <- mid <- numeric(n_phases)
  amp[1] <- exp(theta[idx]); idx <- idx + 1L
  mid[1] <- theta[idx]; idx <- idx + 1L
  scale[1] <- exp(theta[idx]); idx <- idx + 1L
  if (n_phases >= 2L) {
    for (j in 2:n_phases) {
      amp[j] <- exp(theta[idx]); idx <- idx + 1L
      mid[j] <- mid[j - 1L] + exp(theta[idx]); idx <- idx + 1L
      scale[j] <- exp(theta[idx]); idx <- idx + 1L
    }
  }
  list(amp = amp, mid = mid, scale = scale)
}

.agf_multiphase_eval <- function(t, theta, n_phases) {
  p <- .agf_multiphase_unpack(theta, n_phases)
  out <- rep(0, length(t))
  for (j in seq_len(n_phases)) {
    out <- out + .agf_logistic(t, asym = p$amp[j], mid = p$mid[j], scale = p$scale[j])
  }
  out
}

.agf_multiphase_start <- function(t, y, n_phases) {
  tr <- range(t, finite = TRUE)
  yr <- range(y, finite = TRUE)
  span <- max(diff(tr), .Machine$double.eps)
  total <- max(yr[2], max(y, na.rm = TRUE), .Machine$double.eps)
  mids <- as.numeric(stats::quantile(t, probs = seq(0.25, 0.75, length.out = n_phases), names = FALSE, type = 8))
  amps <- rep(total / n_phases, n_phases)
  scales <- rep(span / max(6 * n_phases, 2), n_phases)
  theta <- numeric(3L * n_phases)
  idx <- 1L
  theta[idx] <- log(amps[1]); idx <- idx + 1L
  theta[idx] <- mids[1]; idx <- idx + 1L
  theta[idx] <- log(scales[1]); idx <- idx + 1L
  if (n_phases >= 2L) {
    for (j in 2:n_phases) {
      theta[idx] <- log(amps[j]); idx <- idx + 1L
      theta[idx] <- log(max(mids[j] - mids[j - 1L], span / 20)); idx <- idx + 1L
      theta[idx] <- log(scales[j]); idx <- idx + 1L
    }
  }
  theta
}

.agf_multiphase_fit_one <- function(d, n_phases, start = NULL, n_start = 20L, seed = NULL, control = list()) {
  if (!is.numeric(n_start) || length(n_start) != 1L || n_start < 1) stop("`n_start` must be a positive integer.", call. = FALSE)
  n_start <- as.integer(n_start)
  if (!is.null(seed)) set.seed(seed)
  base <- .agf_multiphase_start(d$.t, d$.y, n_phases)
  if (!is.null(start)) {
    if (!is.numeric(start) || length(start) != length(base) || any(!is.finite(start))) {
      stop("`start` must be a finite numeric vector on the internal transformed scale with length 3 * n_phases.", call. = FALSE)
    }
    base <- as.numeric(start)
  }
  objective <- function(theta) {
    pred <- .agf_multiphase_eval(d$.t, theta, n_phases)
    if (any(!is.finite(pred))) return(.Machine$double.xmax / 100)
    sum((d$.y - pred)^2)
  }
  attempts <- vector("list", n_start)
  rows <- vector("list", n_start)
  span <- diff(range(d$.t))
  for (i in seq_len(n_start)) {
    st <- base
    if (i > 1L) {
      st <- st + stats::rnorm(length(st), sd = c(rep(c(0.35, max(span * 0.04, 0.05), 0.25), n_phases)))
    }
    warnings <- character()
    fit <- tryCatch(
      withCallingHandlers(
        stats::optim(st, objective, method = "BFGS", control = control),
        warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }
      ),
      error = function(e) e
    )
    ok <- is.list(fit) && !inherits(fit, "error") && is.finite(fit$value)
    attempts[[i]] <- fit
    rows[[i]] <- data.frame(
      attempt = i,
      converged = ok && identical(fit$convergence, 0L),
      rss = if (ok) fit$value else Inf,
      warning = paste(unique(warnings), collapse = " | "),
      error = if (inherits(fit, "error")) conditionMessage(fit) else "",
      stringsAsFactors = FALSE
    )
  }
  tab <- do.call(rbind, rows)
  good <- which(is.finite(tab$rss))
  if (!length(good)) stop("No multiphase optimization attempt produced a finite solution.", call. = FALSE)
  best_i <- good[which.min(tab$rss[good])]
  theta <- attempts[[best_i]]$par
  pars <- .agf_multiphase_unpack(theta, n_phases)
  comp <- data.frame(
    phase = seq_len(n_phases), asym = pars$amp, mid = pars$mid, scale = pars$scale,
    stringsAsFactors = FALSE
  )
  pred <- .agf_multiphase_eval(d$.t, theta, n_phases)
  out <- list(
    n_phases = n_phases,
    components = comp,
    theta = theta,
    rss = sum((d$.y - pred)^2),
    sigma = sqrt(sum((d$.y - pred)^2) / max(nrow(d) - length(theta), 1L)),
    fitted = pred,
    residuals = d$.y - pred,
    data = d,
    time_support = range(d$.t),
    response_name = attr(d, "response_name"),
    time_name = attr(d, "time_name"),
    attempts = tab,
    aggregation = attr(d, "aggregation"),
    sampling = attr(d, "sampling")
  )
  class(out) <- "agri_growth_multiphase"
  out
}

#' Fit sums of ordered logistic growth phases
#'
#' @description
#' Fits one to three logistic components whose phase centers are constrained to be
#' ordered. The complete fitted trajectory is the sum of all components. This is
#' useful when a single sigmoid is biologically too simple, but the inferred
#' phases should still be interpreted in light of the experimental design.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,response Column names when `x` is a data frame.
#' @param n_phases Number of logistic phases, currently 1 to 3.
#' @param group Optional grouping column for separate descriptive fits.
#' @param start Optional internal transformed starting vector of length `3 * n_phases`.
#' @param n_start Number of multistart attempts.
#' @param seed Optional random seed.
#' @param aggregate Destructive-sampling aggregation rule passed to the parametric preparation layer.
#' @param control Optional list passed to `stats::optim()`.
#'
#' @return An `agri_growth_multiphase` object or a named collection by group.
#' @export
#'
#' @examples
#' d <- growth_example_data("coffee_diphasic")
#' growth_multiphase(d, time = "day", response = "biomass_g", n_phases = 2, n_start = 3, seed = 1)
#' growth_multiphase(subset(d, treatment == "control"), time = "day", response = "biomass_g", n_phases = 2, n_start = 3)
#' growth_multiphase(d, time = "day", response = "biomass_g", n_phases = 2, group = "treatment", n_start = 2)
growth_multiphase <- function(x, time = NULL, response = NULL, n_phases = 2L,
                              group = NULL, start = NULL, n_start = 20L, seed = NULL,
                              aggregate = c("auto", "none", "mean"), control = list()) {
  aggregate <- match.arg(aggregate)
  if (!is.numeric(n_phases) || length(n_phases) != 1L || !n_phases %in% 1:3) stop("`n_phases` must be 1, 2, or 3.", call. = FALSE)
  n_phases <- as.integer(n_phases)
  d <- .agf_prepare_parametric(x, time = time, response = response, group = group,
                               aggregate = aggregate, warn_pooling = TRUE, warn_dependence = TRUE)
  if (is.null(group)) return(.agf_multiphase_fit_one(d, n_phases, start, n_start, seed, control))
  lev <- unique(d$.group)
  fits <- vector("list", length(lev)); names(fits) <- lev
  for (i in seq_along(lev)) {
    dg <- d[d$.group == lev[i], , drop = FALSE]
    for (at in c("time_name", "response_name", "group_name", "unit_name", "sampling", "aggregation")) attr(dg, at) <- attr(d, at)
    fits[[i]] <- .agf_multiphase_fit_one(dg, n_phases, start, n_start,
                                         if (is.null(seed)) NULL else seed + i - 1L, control)
  }
  out <- list(fits = fits, group = group, groups = lev, n_phases = n_phases, data = d)
  class(out) <- "agri_growth_multiphase_collection"
  out
}

#' Fit a diphasic logistic growth trajectory
#'
#' @inheritParams growth_multiphase
#' @return Same classes as `growth_multiphase()` with two phases.
#' @export
#'
#' @examples
#' d <- growth_example_data("coffee_diphasic")
#' growth_diphasic(d, time = "day", response = "biomass_g", n_start = 3, seed = 1)
#' growth_diphasic(subset(d, treatment == "control"), time = "day", response = "biomass_g", n_start = 2)
#' growth_diphasic(d, time = "day", response = "biomass_g", group = "treatment", n_start = 2)
growth_diphasic <- function(x, time = NULL, response = NULL, group = NULL, start = NULL,
                            n_start = 20L, seed = NULL, aggregate = c("auto", "none", "mean"), control = list()) {
  growth_multiphase(x, time = time, response = response, n_phases = 2L, group = group,
                    start = start, n_start = n_start, seed = seed, aggregate = match.arg(aggregate), control = control)
}

.agf_eval_growth_object <- function(object, time) {
  if (inherits(object, "agri_growth_fit")) return(.agf_eval_internal(object$model, time, object$coefficients_internal))
  if (inherits(object, "agri_growth_multiphase")) return(.agf_multiphase_eval(time, object$theta, object$n_phases))
  if (inherits(object, "agri_growth_smooth")) return(growth_smooth_predict(object, time = time)$fit)
  stop("Unsupported growth object for this operation.", call. = FALSE)
}

.agf_object_support <- function(object) {
  if (!is.null(object$time_support)) return(as.numeric(object$time_support))
  if (inherits(object, "agri_growth_smooth") && !is.null(object$data$.t)) return(range(object$data$.t))
  stop("The growth object does not expose a time support.", call. = FALSE)
}

.agf_num_derivative <- function(object, time, order = 1L) {
  support <- .agf_object_support(object)
  h <- max(diff(support) / 5000, 1e-5)
  if (order == 1L) {
    return((.agf_eval_growth_object(object, time + h) - .agf_eval_growth_object(object, time - h)) / (2 * h))
  }
  if (order == 2L) {
    return((.agf_eval_growth_object(object, time + h) - 2 * .agf_eval_growth_object(object, time) + .agf_eval_growth_object(object, time - h)) / h^2)
  }
  if (order == 4L) {
    return((.agf_eval_growth_object(object, time - 2*h) - 4*.agf_eval_growth_object(object, time - h) +
              6*.agf_eval_growth_object(object, time) - 4*.agf_eval_growth_object(object, time + h) +
              .agf_eval_growth_object(object, time + 2*h)) / h^4)
  }
  stop("Only derivative orders 1, 2, and 4 are supported.", call. = FALSE)
}

.agf_roots_on_grid <- function(fun, interval, n = 2001L, tol = 1e-7) {
  grid <- seq(interval[1], interval[2], length.out = n)
  val <- fun(grid)
  ok <- is.finite(val)
  roots <- numeric()
  exact <- which(ok & abs(val) <= tol)
  if (length(exact)) roots <- c(roots, grid[exact])
  for (i in seq_len(length(grid) - 1L)) {
    if (!ok[i] || !ok[i + 1L]) next
    if (val[i] * val[i + 1L] < 0) {
      rt <- tryCatch(stats::uniroot(fun, c(grid[i], grid[i + 1L]), tol = tol)$root, error = function(e) NA_real_)
      if (is.finite(rt)) roots <- c(roots, rt)
    }
  }
  if (!length(roots)) return(numeric())
  roots <- sort(unique(round(roots, digits = 8)))
  roots[c(TRUE, diff(roots) > max(tol * 10, diff(interval) / n / 3))]
}

#' Locate stability points from the fourth derivative
#'
#' @description
#' Locates zeros of the fourth derivative of the complete fitted curve. For a
#' multiphase sum, differentiation is applied to the sum rather than to each
#' component separately.
#'
#' @param object A parametric, multiphase, or supported smooth growth object.
#' @param interval Optional search interval. Defaults to the observed time support.
#' @param n Grid density for locating sign changes.
#' @return A data frame of stability times and fitted responses.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' f <- growth_fit(subset(d, cultivar == "C1"), "logistic", time = "day", response = "biomass_g")
#' growth_stability(f)
#' growth_stability(f, n = 501)
#' growth_stability(growth_diphasic(growth_example_data("coffee_diphasic"), time = "day", response = "biomass_g", n_start = 2), n = 501)
growth_stability <- function(object, interval = NULL, n = 2001L) {
  n <- .agf_grid_n(n, min_n = 101L, name = "n")
  if (inherits(object, "agri_growth_multiphase_collection")) {
    out <- lapply(names(object$fits), function(g) { z <- growth_stability(object$fits[[g]], interval, n); z$group <- g; z })
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  if (is.null(interval)) interval <- .agf_object_support(object)
  if (!is.numeric(interval) || length(interval) != 2L || any(!is.finite(interval)) || interval[1] >= interval[2]) stop("`interval` must contain two increasing finite numbers.", call. = FALSE)
  roots <- .agf_roots_on_grid(function(tt) .agf_num_derivative(object, tt, order = 4L), interval, n = n)
  data.frame(stability_time = roots, response = if (length(roots)) .agf_eval_growth_object(object, roots) else numeric(), stringsAsFactors = FALSE)
}

#' Estimate a piecewise-linear growth changepoint
#'
#' @description
#' Searches candidate internal times and fits a continuous two-slope linear model
#' `response ~ time + pmax(time - breakpoint, 0)`. The current implementation is
#' intentionally limited to one breakpoint and is intended as an exploratory
#' structural diagnostic rather than a replacement for a full segmented model.
#'
#' @param data Data frame.
#' @param time,response Column names.
#' @param min_segment Minimum number of distinct times on each side.
#' @param candidates Optional candidate breakpoint times.
#' @return An `agri_growth_changepoint` object.
#' @export
#'
#' @examples
#' d <- growth_example_data("coffee_diphasic")
#' growth_changepoint(subset(d, treatment == "control"), time = "day", response = "biomass_g")
#' growth_changepoint(subset(d, treatment == "stress"), time = "day", response = "biomass_g")
#' growth_changepoint(subset(d, treatment == "control"), time = "day", response = "biomass_g", min_segment = 3)
growth_changepoint <- function(data, time, response, min_segment = 3L, candidates = NULL) {
  if (!is.numeric(min_segment) || length(min_segment) != 1L || !is.finite(min_segment) || min_segment < 2 || abs(min_segment - round(min_segment)) > 1e-8) stop("`min_segment` must be an integer of at least 2.", call. = FALSE)
  min_segment <- as.integer(min_segment)
  .agf_assert_data_frame(data); .agf_assert_column(data, time, "time", FALSE); .agf_assert_column(data, response, "response", FALSE)
  t <- as.numeric(data[[time]]); y <- as.numeric(data[[response]])
  keep <- is.finite(t) & is.finite(y); t <- t[keep]; y <- y[keep]
  ut <- sort(unique(t))
  if (length(ut) < 2L * min_segment + 1L) stop("Not enough distinct times for the requested `min_segment`.", call. = FALSE)
  if (is.null(candidates)) candidates <- ut[(min_segment + 1L):(length(ut) - min_segment)]
  candidates <- candidates[candidates > min(ut) & candidates < max(ut)]
  if (!length(candidates)) stop("No admissible changepoint candidates remain.", call. = FALSE)
  fits <- lapply(candidates, function(cp) {
    hinge <- pmax(t - cp, 0)
    fit <- stats::lm(y ~ t + hinge)
    c(cp = cp, rss = sum(stats::residuals(fit)^2), aic = stats::AIC(fit))
  })
  tab <- as.data.frame(do.call(rbind, fits)); best <- which.min(tab$rss); cp <- tab$cp[best]
  hinge <- pmax(t - cp, 0); fit <- stats::lm(y ~ t + hinge); cf <- stats::coef(fit)
  out <- list(breakpoint = cp, fit = fit, candidates = tab,
              slope_before = unname(cf[["t"]]), slope_after = unname(cf[["t"]] + cf[["hinge"]]),
              data = data[keep, , drop = FALSE], time = time, response = response)
  class(out) <- "agri_growth_changepoint"
  out
}

#' Declare a known biological disturbance or management event
#'
#' @param data Data frame.
#' @param time,response Column names.
#' @param event_time Known event time.
#' @param unit Optional persistent-unit column.
#' @param event_type Descriptive event label.
#' @param event_amount Optional known amount removed or applied.
#' @return An `agri_growth_event` object with event-centered variables.
#' @export
#'
#' @examples
#' d <- growth_example_data("bean_defoliation")
#' growth_event(d, time = "day", response = "total_mass_g", event_time = 21, unit = "plant_id", event_type = "defoliation")
#' growth_event(d, time = "day", response = "leaf_area_m2", event_time = 21, unit = "plant_id")
#' growth_event(subset(d, treatment == "defoliated"), time = "day", response = "total_mass_g", event_time = 21, event_amount = 2)
growth_event <- function(data, time, response, event_time, unit = NULL,
                         event_type = "disturbance", event_amount = NULL) {
  .agf_assert_data_frame(data); .agf_assert_column(data, time, "time", FALSE); .agf_assert_column(data, response, "response", FALSE)
  .agf_assert_column(data, unit, "unit", TRUE)
  if (!is.numeric(event_time) || length(event_time) != 1L || !is.finite(event_time)) stop("`event_time` must be a finite scalar.", call. = FALSE)
  outd <- data
  outd$.event_centered_time <- as.numeric(outd[[time]]) - event_time
  outd$.post_event <- outd$.event_centered_time >= 0
  outd$.event_type <- event_type
  out <- list(data = outd, time = time, response = response, unit = unit,
              event_time = event_time, event_type = event_type, event_amount = event_amount)
  class(out) <- "agri_growth_event"
  out
}

.agf_defol_simulate <- function(times, initial, losses, nar, flam, gamma, step = 0.25) {
  state <- as.numeric(initial); names(state) <- c("W", "L", "A")
  rows <- data.frame(time = times[1], W = state[1], L = state[2], A = state[3])
  current <- times[1]
  for (target in times[-1]) {
    while (current < target - 1e-12) {
      dt <- min(step, target - current)
      W <- state[1]; L <- state[2]; A <- state[3]
      if (W <= 0 || L <= 0 || A <= 0) return(NULL)
      sla <- A / L; lar <- A / W; rgr <- lar * nar; G <- W * rgr
      state[1] <- W + G * dt
      state[2] <- L + flam * G * dt
      state[3] <- A + gamma * sla * flam * G * dt
      current <- current + dt
    }
    ix <- which(abs(losses$time - target) < 1e-8)
    if (length(ix)) {
      state[1] <- state[1] - sum(losses$total_loss[ix], na.rm = TRUE)
      state[2] <- state[2] - sum(losses$leaf_mass_loss[ix], na.rm = TRUE)
      state[3] <- state[3] - sum(losses$leaf_area_loss[ix], na.rm = TRUE)
    }
    if (any(!is.finite(state)) || any(state <= 0)) return(NULL)
    rows <- rbind(rows, data.frame(time = target, W = state[1], L = state[2], A = state[3]))
  }
  rows
}

.agf_defol_one <- function(d, time, total_mass, leaf_mass, leaf_area, total_loss, leaf_mass_loss, leaf_area_loss, step) {
  o <- order(d[[time]]); d <- d[o, , drop = FALSE]
  times <- sort(unique(as.numeric(d[[time]])))
  if (length(times) < 2L) stop("At least two observation times are required for iterative defoliation analysis.", call. = FALSE)
  obs <- stats::aggregate(d[c(total_mass, leaf_mass, leaf_area)], list(time = d[[time]]), mean, na.rm = TRUE)
  names(obs)[2:4] <- c("W", "L", "A")
  zloss <- function(nm) if (is.null(nm)) rep(0, nrow(d)) else as.numeric(d[[nm]])
  lossdf <- data.frame(time = as.numeric(d[[time]]), total_loss = zloss(total_loss), leaf_mass_loss = zloss(leaf_mass_loss), leaf_area_loss = zloss(leaf_area_loss))
  lossdf <- stats::aggregate(lossdf[2:4], list(time = lossdf$time), sum, na.rm = TRUE)
  sdev <- c(stats::sd(obs$W), stats::sd(obs$L), stats::sd(obs$A))
  means <- c(mean(obs$W), mean(obs$L), mean(obs$A))
  sdev[!is.finite(sdev)] <- 0
  scalev <- pmax(sdev, abs(means) * 0.05, 1e-8)
  objective <- function(theta) {
    nar <- exp(theta[1]); flam <- stats::plogis(theta[2]); gamma <- exp(theta[3])
    sim <- .agf_defol_simulate(obs$time, as.numeric(obs[1, c("W","L","A")]), lossdf, nar, flam, gamma, step)
    if (is.null(sim) || nrow(sim) != nrow(obs)) return(.Machine$double.xmax / 100)
    err <- c((sim$W - obs$W) / scalev[1], (sim$L - obs$L) / scalev[2], (sim$A - obs$A) / scalev[3])
    sum(err^2)
  }
  init_nar <- max(diff(log(pmax(obs$W, 1e-8))) / pmax(diff(obs$time), 1e-8), na.rm = TRUE) / max(mean(obs$A / obs$W), 1e-8)
  if (!is.finite(init_nar) || init_nar <= 0) init_nar <- 1
  fit <- stats::optim(c(log(init_nar), stats::qlogis(0.35), log(1)), objective, method = "Nelder-Mead")
  pars <- c(NAR = exp(fit$par[1]), flam = stats::plogis(fit$par[2]), gamma = exp(fit$par[3]))
  sim <- .agf_defol_simulate(obs$time, as.numeric(obs[1, c("W","L","A")]), lossdf, pars[["NAR"]], pars[["flam"]], pars[["gamma"]], step)
  list(parameters = pars, observed = obs, simulated = sim, objective = fit$value, convergence = fit$convergence)
}

#' Iterative growth analysis for repeated leaf-mass losses
#'
#' @description
#' Implements a design-oriented numerical version of the iterative approach of
#' Anten and Ackerly. Losses are treated as measured inputs. The current model
#' estimates a constant NAR, a constant allocation fraction to leaf lamina, and
#' a multiplicative SLA factor for newly produced leaves over the analyzed window.
#'
#' @param data Data frame containing state measurements and measured losses.
#' @param time,total_mass,leaf_mass,leaf_area Column names for time and plant states.
#' @param total_loss,leaf_mass_loss,leaf_area_loss Optional loss columns; missing columns imply zero loss.
#' @param unit Optional persistent-unit column. Parameters are estimated separately by unit.
#' @param step Numerical integration step in time units.
#' @return An `agri_growth_defoliation` object.
#' @export
#'
#' @examples
#' d <- growth_example_data("bean_defoliation")
#' growth_defoliation(subset(d, plant_id == unique(d$plant_id)[1]), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", total_loss="total_loss_g", leaf_mass_loss="leaf_mass_loss_g", leaf_area_loss="leaf_area_loss_m2")
#' growth_defoliation(subset(d, treatment == "defoliated"), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", total_loss="total_loss_g", leaf_mass_loss="leaf_mass_loss_g", leaf_area_loss="leaf_area_loss_m2", unit="plant_id")
#' growth_defoliation(subset(d, treatment == "control"), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", unit="plant_id", step=0.5)
growth_defoliation <- function(data, time, total_mass, leaf_mass, leaf_area,
                               total_loss = NULL, leaf_mass_loss = NULL, leaf_area_loss = NULL,
                               unit = NULL, step = 0.25) {
  .agf_assert_data_frame(data)
  for (nm in c(time, total_mass, leaf_mass, leaf_area)) .agf_assert_column(data, nm, nm, FALSE)
  for (nm in c(total_loss, leaf_mass_loss, leaf_area_loss, unit)) .agf_assert_column(data, nm, nm %||% "optional", TRUE)
  if (!is.numeric(step) || length(step) != 1L || !is.finite(step) || step <= 0) stop("`step` must be a positive finite scalar.", call. = FALSE)
  if (is.null(unit)) {
    fits <- list(.all = .agf_defol_one(data, time, total_mass, leaf_mass, leaf_area, total_loss, leaf_mass_loss, leaf_area_loss, step))
  } else {
    lev <- unique(data[[unit]]); fits <- lapply(lev, function(u) .agf_defol_one(data[data[[unit]] == u, , drop = FALSE], time, total_mass, leaf_mass, leaf_area, total_loss, leaf_mass_loss, leaf_area_loss, step)); names(fits) <- as.character(lev)
  }
  par_table <- do.call(rbind, lapply(names(fits), function(id) data.frame(unit = id, as.list(fits[[id]]$parameters), objective = fits[[id]]$objective, convergence = fits[[id]]$convergence, stringsAsFactors = FALSE)))
  rownames(par_table) <- NULL
  out <- list(fits = fits, parameters = par_table, unit = unit, time = time, total_mass = total_mass, leaf_mass = leaf_mass, leaf_area = leaf_area)
  class(out) <- "agri_growth_defoliation"
  out
}

.agf_auc_simple <- function(t, y) {
  o <- order(t); t <- t[o]; y <- y[o]
  if (length(t) < 2L) return(NA_real_)
  sum(diff(t) * (head(y, -1L) + utils::tail(y, -1L)) / 2)
}

#' Quantify compensatory growth relative to a control
#'
#' @param data Data frame or `agri_growth_event` object.
#' @param group Grouping column.
#' @param control Value identifying the control group.
#' @param response Response column.
#' @param time Optional time column, required for `metric = "auc"` or `"slope"`.
#' @param unit Optional persistent-unit column used to form replicate summaries before comparison.
#' @param metric One of `"final"`, `"auc"`, or `"slope"`.
#' @return A data frame with group summaries and compensation ratios relative to control.
#' @export
#'
#' @examples
#' d <- growth_example_data("bean_defoliation")
#' growth_compensation(d, group="treatment", control="control", response="total_mass_g", time="day", unit="plant_id", metric="final")
#' growth_compensation(d, group="treatment", control="control", response="total_mass_g", time="day", unit="plant_id", metric="auc")
#' growth_compensation(d, group="treatment", control="control", response="leaf_area_m2", time="day", unit="plant_id", metric="slope")
growth_compensation <- function(data, group, control, response, time = NULL, unit = NULL,
                                metric = c("final", "auc", "slope")) {
  metric <- match.arg(metric)
  if (inherits(data, "agri_growth_event")) data <- data$data
  .agf_assert_data_frame(data); .agf_assert_column(data, group, "group", FALSE); .agf_assert_column(data, response, "response", FALSE)
  .agf_assert_column(data, time, "time", metric == "final"); .agf_assert_column(data, unit, "unit", TRUE)
  if (!control %in% data[[group]]) stop("`control` was not found in the grouping column.", call. = FALSE)
  if (is.null(unit)) {
    key <- factor(data[[group]])
  } else {
    key <- interaction(data[[group]], data[[unit]], drop = TRUE, lex.order = TRUE)
  }
  spl <- split(data, key)
  rows <- lapply(spl, function(z) {
    g <- as.character(z[[group]][1]); id <- if (is.null(unit)) ".group" else as.character(z[[unit]][1])
    value <- if (metric == "final") {
      if (is.null(time)) utils::tail(z[[response]], 1L) else z[[response]][which.max(z[[time]])]
    } else if (metric == "auc") {
      .agf_auc_simple(z[[time]], z[[response]])
    } else {
      if (nrow(z) < 2L) NA_real_ else unname(stats::coef(stats::lm(z[[response]] ~ z[[time]]))[2])
    }
    data.frame(group = g, unit = id, value = value, stringsAsFactors = FALSE)
  })
  u <- do.call(rbind, rows)
  lev <- unique(u$group)
  out <- do.call(rbind, lapply(lev, function(g) {
    v <- u$value[u$group == g]
    data.frame(group = g, mean = mean(v, na.rm = TRUE), sd = stats::sd(v, na.rm = TRUE),
               n = sum(is.finite(v)), stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  cmean <- out$mean[out$group == as.character(control)][1]
  out$compensation_ratio <- out$mean / cmean
  out$difference_from_control <- out$mean - cmean
  out$metric <- metric
  out
}

#' Fit a reciprocal plant-size versus density relationship
#'
#' @param data Data frame.
#' @param density,plant_mass Column names.
#' @return An `agri_growth_density` object based on `1 / plant_mass = a + b * density`.
#' @export
#'
#' @examples
#' d <- growth_example_data("maize_density")
#' growth_density(d, density="density_plants_m2", plant_mass="plant_mass_g")
#' growth_density(subset(d, nitrogen == "high"), density="density_plants_m2", plant_mass="plant_mass_g")
#' coef(growth_density(d, density="density_plants_m2", plant_mass="plant_mass_g")$fit)
growth_density <- function(data, density, plant_mass) {
  .agf_assert_data_frame(data); .agf_assert_column(data, density, "density", FALSE); .agf_assert_column(data, plant_mass, "plant_mass", FALSE)
  d <- as.numeric(data[[density]]); w <- as.numeric(data[[plant_mass]])
  keep <- is.finite(d) & is.finite(w) & d >= 0 & w > 0
  if (sum(keep) < 3L) stop("At least three positive plant-mass observations are required.", call. = FALSE)
  dd <- data.frame(inv_mass = 1 / w[keep], density = d[keep])
  fit <- stats::lm(inv_mass ~ density, data = dd)
  out <- list(fit = fit, density = d[keep], plant_mass = w[keep], density_name = density, plant_mass_name = plant_mass)
  class(out) <- "agri_growth_density"
  out
}

#' Calculate a transparent size-distance neighborhood competition index
#'
#' @param data Data frame with planar coordinates and plant size.
#' @param id,x,y,size Column names.
#' @param radius Maximum neighborhood radius.
#' @param distance_power Exponent applied to inter-plant distance.
#' @param size_power Exponent applied to the neighbor-to-focal size ratio.
#' @return A data frame with one competition index per focal plant.
#' @export
#'
#' @examples
#' d <- growth_example_data("tree_competition")
#' growth_neighbor(d, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=3)
#' growth_neighbor(d, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=5, distance_power=2)
#' growth_neighbor(d, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=4, size_power=0)
growth_neighbor <- function(data, id, x, y, size, radius = Inf, distance_power = 1, size_power = 1) {
  .agf_assert_data_frame(data)
  for (nm in c(id, x, y, size)) .agf_assert_column(data, nm, nm, FALSE)
  if (!is.numeric(radius) || length(radius) != 1L || radius <= 0) stop("`radius` must be positive.", call. = FALSE)
  if (!is.numeric(distance_power) || length(distance_power) != 1L || distance_power < 0) stop("`distance_power` must be non-negative.", call. = FALSE)
  if (!is.numeric(size_power) || length(size_power) != 1L) stop("`size_power` must be numeric.", call. = FALSE)
  xx <- as.numeric(data[[x]]); yy <- as.numeric(data[[y]]); ss <- as.numeric(data[[size]])
  if (any(!is.finite(c(xx, yy, ss))) || any(ss <= 0)) stop("Coordinates must be finite and size must be positive.", call. = FALSE)
  n <- nrow(data); idx <- numeric(n); nnei <- integer(n)
  for (i in seq_len(n)) {
    dist <- sqrt((xx - xx[i])^2 + (yy - yy[i])^2)
    keep <- seq_len(n) != i & dist > 0 & dist <= radius
    nnei[i] <- sum(keep)
    if (any(keep)) idx[i] <- sum((ss[keep] / ss[i])^size_power / pmax(dist[keep], .Machine$double.eps)^distance_power)
  }
  data.frame(id = data[[id]], competition_index = idx, n_neighbors = nnei, radius = radius, stringsAsFactors = FALSE)
}

.agf_comp_rhs <- function(w, r, K, alpha) {
  pressure <- as.numeric(alpha %*% w)
  r * w * (1 - (w + pressure) / K)
}

#' Simulate coupled logistic competition among plants
#'
#' @param initial_size Positive initial sizes.
#' @param times Increasing output times.
#' @param r Intrinsic rates, scalar or one per plant.
#' @param K Carrying sizes, scalar or one per plant.
#' @param competition_matrix Square matrix of non-negative inter-plant competition coefficients. Diagonal entries are ignored.
#' @param dt Maximum RK4 integration step.
#' @return An `agri_growth_competition` object with long-format simulated trajectories.
#' @export
#'
#' @examples
#' growth_competition(c(1,1), times=0:5, r=0.4, K=20, competition_matrix=matrix(c(0,.2,.2,0),2), dt=.1)
#' growth_competition(c(1,2,1), times=0:4, r=c(.3,.4,.35), K=25, competition_matrix=matrix(0,3,3))
#' growth_competition(c(2,2), times=c(0,1,2), r=.5, K=c(15,20), competition_matrix=matrix(c(0,.5,.1,0),2), dt=.05)
growth_competition <- function(initial_size, times, r, K, competition_matrix, dt = 0.1) {
  if (!is.numeric(initial_size) || any(!is.finite(initial_size)) || any(initial_size <= 0)) stop("`initial_size` must contain positive finite values.", call. = FALSE)
  n <- length(initial_size)
  if (!is.numeric(r) || !length(r) %in% c(1L, n) || !is.numeric(K) || !length(K) %in% c(1L, n)) {
    stop("`r` and `K` must be scalars or have one value per plant.", call. = FALSE)
  }
  if (length(r) == 1L) r <- rep(r, n)
  if (length(K) == 1L) K <- rep(K, n)
  if (any(!is.finite(r)) || any(r < 0) || any(!is.finite(K)) || any(K <= 0)) stop("`r` must be non-negative and `K` positive.", call. = FALSE)
  if (!is.matrix(competition_matrix) || any(dim(competition_matrix) != c(n,n)) || any(!is.finite(competition_matrix)) || any(competition_matrix < 0)) stop("`competition_matrix` must be a finite non-negative n by n matrix.", call. = FALSE)
  alpha <- competition_matrix; diag(alpha) <- 0
  times <- sort(unique(as.numeric(times)))
  if (length(times) < 2L || any(!is.finite(times))) stop("`times` must contain at least two finite values.", call. = FALSE)
  if (!is.numeric(dt) || length(dt) != 1L || !is.finite(dt) || dt <= 0) stop("`dt` must be positive.", call. = FALSE)
  W <- as.numeric(initial_size); current <- times[1]
  out <- data.frame(time = current, plant = seq_len(n), size = W)
  for (target in times[-1]) {
    while (current < target - 1e-12) {
      h <- min(dt, target - current)
      k1 <- .agf_comp_rhs(W, r, K, alpha)
      k2 <- .agf_comp_rhs(W + h*k1/2, r, K, alpha)
      k3 <- .agf_comp_rhs(W + h*k2/2, r, K, alpha)
      k4 <- .agf_comp_rhs(W + h*k3, r, K, alpha)
      W <- pmax(W + h*(k1 + 2*k2 + 2*k3 + k4)/6, 0)
      current <- current + h
    }
    out <- rbind(out, data.frame(time = target, plant = seq_len(n), size = W))
  }
  ans <- list(trajectory = out, initial_size = initial_size, r = r, K = K, competition_matrix = alpha, dt = dt)
  class(ans) <- "agri_growth_competition"
  ans
}

.agf_growth_upper <- function(object) {
  if (inherits(object, "agri_growth_fit")) return(.agf_upper_level(object))
  if (inherits(object, "agri_growth_multiphase")) return(sum(object$components$asym))
  NA_real_
}

#' Find the time a fitted growth trajectory crosses a threshold
#'
#' @param object Parametric, multiphase, or supported smooth growth object.
#' @param threshold Absolute threshold or fraction depending on `type`.
#' @param type `"absolute"` or `"fraction"`.
#' @param interval Optional search interval. Defaults to observed support.
#' @param direction `"increasing"` or `"decreasing"` crossing.
#' @param n Grid density.
#' @return A data frame with crossing times and fitted responses.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid"); f <- growth_fit(subset(d,cultivar=="C1"),"logistic",time="day",response="biomass_g")
#' growth_threshold(f, .5, type="fraction")
#' growth_threshold(f, 100, type="absolute")
#' growth_threshold(growth_diphasic(growth_example_data("coffee_diphasic"), time="day", response="biomass_g", n_start=2), .8, type="fraction")
growth_threshold <- function(object, threshold, type = c("absolute", "fraction"),
                             interval = NULL, direction = c("increasing", "decreasing"), n = 2001L) {
  n <- .agf_grid_n(n, min_n = 101L, name = "n")
  type <- match.arg(type); direction <- match.arg(direction)
  if (!is.numeric(threshold) || length(threshold) != 1L || !is.finite(threshold)) stop("`threshold` must be a finite scalar.", call. = FALSE)
  target <- threshold
  if (type == "fraction") {
    if (threshold < 0 || threshold > 1) stop("Fractional thresholds must be between 0 and 1.", call. = FALSE)
    upper <- .agf_growth_upper(object)
    if (!is.finite(upper)) stop("A finite upper level is required for fractional thresholds.", call. = FALSE)
    target <- threshold * upper
  }
  if (is.null(interval)) interval <- .agf_object_support(object)
  roots <- .agf_roots_on_grid(function(tt) .agf_eval_growth_object(object, tt) - target, interval, n)
  if (length(roots)) {
    slopes <- .agf_num_derivative(object, roots, 1L)
    keep <- if (direction == "increasing") slopes >= 0 else slopes <= 0
    roots <- roots[keep]
  }
  data.frame(threshold = threshold, type = type, target_response = target,
             time = roots, response = if (length(roots)) .agf_eval_growth_object(object, roots) else numeric(), stringsAsFactors = FALSE)
}

#' Estimate the time of practical growth plateau
#'
#' @param object Parametric or multiphase fitted growth object.
#' @param criterion `"rate"` or `"response"`.
#' @param rate_fraction Fraction of the maximum absolute rate used by the rate criterion.
#' @param response_fraction Fraction of the finite upper response used by the response criterion.
#' @param interval Optional search interval. Defaults to observed support; can be extended by the user.
#' @param n Grid density.
#' @return A one-row data frame with the practical plateau time.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid"); f <- growth_fit(subset(d,cultivar=="C1"),"logistic",time="day",response="biomass_g")
#' growth_plateau_time(f, criterion="response")
#' growth_plateau_time(f, criterion="rate", rate_fraction=.1)
#' growth_plateau_time(growth_diphasic(growth_example_data("coffee_diphasic"), time="day", response="biomass_g", n_start=2), criterion="response", response_fraction=.9)
growth_plateau_time <- function(object, criterion = c("rate", "response"), rate_fraction = 0.05,
                                response_fraction = 0.95, interval = NULL, n = 3001L) {
  n <- .agf_grid_n(n, min_n = 101L, name = "n")
  criterion <- match.arg(criterion)
  if (is.null(interval)) interval <- .agf_object_support(object)
  grid <- seq(interval[1], interval[2], length.out = n)
  if (criterion == "response") {
    z <- growth_threshold(object, response_fraction, type = "fraction", interval = interval, n = n)
    pt <- if (nrow(z)) min(z$time) else NA_real_; target <- if (nrow(z)) z$target_response[1] else NA_real_
    return(data.frame(criterion = criterion, plateau_time = pt, threshold = target, stringsAsFactors = FALSE))
  }
  if (!is.numeric(rate_fraction) || rate_fraction <= 0 || rate_fraction >= 1) stop("`rate_fraction` must be between 0 and 1.", call. = FALSE)
  der <- .agf_num_derivative(object, grid, 1L); imax <- which.max(der); maxr <- der[imax]
  after <- seq.int(imax, length(grid)); hit <- after[der[after] <= rate_fraction * maxr]
  pt <- if (length(hit)) grid[hit[1]] else NA_real_
  data.frame(criterion = criterion, plateau_time = pt, threshold = rate_fraction * maxr, maximum_rate = maxr, stringsAsFactors = FALSE)
}

#' Optimize a model-conditioned harvest time
#'
#' @description
#' Maximizes a user-defined net value curve. The result is conditional on the
#' fitted biological trajectory and the supplied economic assumptions; it is not
#' an automatic agronomic recommendation.
#'
#' @param object Parametric or multiphase fitted growth object.
#' @param price Value per unit of response.
#' @param cost_per_time Linear holding or production cost per time unit.
#' @param discount_rate Continuous discount rate per time unit.
#' @param harvest_cost Fixed harvest cost.
#' @param interval Optional optimization interval. Defaults to observed support.
#' @param n Grid density.
#' @return An `agri_growth_harvest` object.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid"); f <- growth_fit(subset(d,cultivar=="C1"),"logistic",time="day",response="biomass_g")
#' growth_harvest_opt(f, price=1, cost_per_time=.2)
#' growth_harvest_opt(f, price=1, discount_rate=.01)
#' growth_harvest_opt(growth_diphasic(growth_example_data("coffee_diphasic"),time="day",response="biomass_g",n_start=2), price=2, cost_per_time=.1)
growth_harvest_opt <- function(object, price = 1, cost_per_time = 0, discount_rate = 0,
                               harvest_cost = 0, interval = NULL, n = 2001L) {
  n <- .agf_grid_n(n, min_n = 101L, name = "n")
  vals <- c(price, cost_per_time, discount_rate, harvest_cost)
  if (any(!is.finite(vals)) || price < 0 || cost_per_time < 0 || discount_rate < 0 || harvest_cost < 0) stop("Economic inputs must be finite and non-negative.", call. = FALSE)
  if (is.null(interval)) interval <- .agf_object_support(object)
  grid <- seq(interval[1], interval[2], length.out = n); y <- .agf_eval_growth_object(object, grid)
  net <- price * y * exp(-discount_rate * (grid - grid[1])) - cost_per_time * (grid - grid[1]) - harvest_cost
  i <- which.max(net)
  out <- list(optimum_time = grid[i], response = y[i], net_value = net[i], curve = data.frame(time=grid,response=y,net_value=net), assumptions = list(price=price,cost_per_time=cost_per_time,discount_rate=discount_rate,harvest_cost=harvest_cost))
  class(out) <- "agri_growth_harvest"
  out
}

#' Propose an observation schedule from a fitted trajectory
#'
#' @description
#' Produces an equal-time schedule or a heuristic schedule that allocates more
#' observations where absolute growth rate and curvature are large. It is a
#' planning heuristic, not a D-optimal design.
#'
#' @param object Optional fitted growth object.
#' @param time_range Two-number range when `object` is absent or when an explicit range is desired.
#' @param n Number of observation times.
#' @param method `"rate_curvature"` or `"equal"`.
#' @param grid_size Internal grid size for the heuristic.
#' @return A data frame of proposed times.
#' @export
#'
#' @examples
#' growth_schedule(time_range=c(0,100), n=6, method="equal")
#' d <- growth_example_data("sunflower_sigmoid"); f <- growth_fit(subset(d,cultivar=="C1"),"logistic",time="day",response="biomass_g")
#' growth_schedule(f, n=6)
#' growth_schedule(f, time_range=c(0,80), n=8, method="rate_curvature")
growth_schedule <- function(object = NULL, time_range = NULL, n = 6L,
                            method = c("rate_curvature", "equal"), grid_size = 2001L) {
  method <- match.arg(method)
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 2 || abs(n - round(n)) > 1e-8) stop("`n` must be an integer of at least 2.", call. = FALSE)
  n <- as.integer(n)
  grid_size <- .agf_grid_n(grid_size, min_n = max(101L, n * 5L), name = "grid_size")
  if (is.null(time_range)) {
    if (is.null(object)) stop("Supply `object` or `time_range`.", call. = FALSE)
    time_range <- .agf_object_support(object)
  }
  if (!is.numeric(time_range) || length(time_range)!=2L || any(!is.finite(time_range)) || time_range[1]>=time_range[2]) stop("`time_range` must contain two increasing finite values.", call. = FALSE)
  if (method == "equal" || is.null(object)) {
    tt <- seq(time_range[1], time_range[2], length.out = n)
    return(data.frame(order=seq_len(n), time=tt, method="equal", stringsAsFactors=FALSE))
  }
  grid <- seq(time_range[1], time_range[2], length.out = grid_size)
  d1 <- abs(.agf_num_derivative(object, grid, 1L)); d2 <- abs(.agf_num_derivative(object, grid, 2L))
  norm <- function(z) if (max(z,na.rm=TRUE) > 0) z/max(z,na.rm=TRUE) else rep(0,length(z))
  w <- 0.65*norm(d1) + 0.35*norm(d2) + 1e-8
  cw <- cumsum(w)/sum(w); probs <- seq(0,1,length.out=n)
  tt <- stats::approx(x = c(0, cw), y = c(grid[1], grid), xout = probs, ties = "ordered", rule = 2)$y
  tt[1] <- grid[1]; tt[n] <- utils::tail(grid,1)
  data.frame(order=seq_len(n), time=as.numeric(tt), method="rate_curvature", stringsAsFactors=FALSE)
}

#' Simulate plant growth observations for design exploration
#'
#' @param model Built-in parametric model.
#' @param parameters Named public parameter vector.
#' @param times Observation times.
#' @param n_unit Number of persistent experimental units.
#' @param sigma Residual standard deviation.
#' @param random_asym_sd Optional log-scale random standard deviation applied to the upper-level parameter.
#' @param treatment Optional treatment labels of length `n_unit`.
#' @param treatment_multiplier Optional named multiplier applied to the upper-level parameter by treatment.
#' @param seed Optional seed.
#' @return A simulated long-format data frame.
#' @export
#'
#' @examples
#' growth_design_sim("logistic", c(asym=100,mid=30,scale=8), times=seq(0,60,10), n_unit=6, sigma=3, seed=1)
#' growth_design_sim("gompertz", c(asym=80,mid=25,scale=7), times=0:5*10, n_unit=4, sigma=2, random_asym_sd=.1, seed=2)
#' growth_design_sim("logistic", c(asym=100,mid=30,scale=8), times=seq(0,60,10), n_unit=8, sigma=3, treatment=rep(c("C","T"),each=4), treatment_multiplier=c(C=1,T=1.15), seed=3)
growth_design_sim <- function(model, parameters, times, n_unit = 12L, sigma = 1,
                              random_asym_sd = 0, treatment = NULL, treatment_multiplier = NULL,
                              seed = NULL) {
  model <- .agf_model_alias(model); internal <- .agf_public_to_internal(model, parameters)
  times <- sort(unique(as.numeric(times))); n_unit <- as.integer(n_unit)
  if (n_unit < 1L || length(times) < 2L || any(!is.finite(times))) stop("`n_unit` must be positive and `times` must contain at least two finite values.", call. = FALSE)
  if (!is.numeric(sigma) || sigma < 0 || !is.finite(sigma) || !is.numeric(random_asym_sd) || random_asym_sd < 0) stop("`sigma` and `random_asym_sd` must be non-negative.", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)
  if (is.null(treatment)) treatment <- rep("all", n_unit)
  if (length(treatment) != n_unit) stop("`treatment` must have length `n_unit`.", call. = FALSE)
  rows <- vector("list", n_unit)
  for (i in seq_len(n_unit)) {
    p <- internal
    public <- .agf_internal_to_public(model, p)
    upper_name <- if (model == "beta_growth") "wmax" else if (model == "expolinear") "cm" else "asym"
    if (upper_name %in% names(public)) {
      mult <- 1
      if (!is.null(treatment_multiplier)) {
        if (is.null(names(treatment_multiplier)) || !as.character(treatment[i]) %in% names(treatment_multiplier)) stop("`treatment_multiplier` must be named for all treatment levels.", call. = FALSE)
        mult <- treatment_multiplier[[as.character(treatment[i])]]
        if (!is.numeric(mult) || length(mult) != 1L || !is.finite(mult) || mult <= 0) stop("Treatment multipliers must be positive finite scalars.", call. = FALSE)
      }
      public[[upper_name]] <- public[[upper_name]] * mult * exp(stats::rnorm(1,0,random_asym_sd))
      p <- .agf_public_to_internal(model, public)
    }
    mu <- .agf_eval_internal(model, times, p)
    rows[[i]] <- data.frame(unit=paste0("U",i), treatment=as.character(treatment[i]), time=times, expected=mu, response=mu+stats::rnorm(length(times),0,sigma), stringsAsFactors=FALSE)
  }
  out <- do.call(rbind, rows); rownames(out) <- NULL; out
}

#' Approximate power for a derived growth-trait contrast
#'
#' @description
#' Uses Monte Carlo sampling of unit-level derived traits. It is intended for
#' planning from a pilot estimate of the trait standard deviation and does not
#' replace simulation of the complete mixed or Bayesian growth model.
#'
#' @param effect Expected treatment-minus-control difference in the derived trait.
#' @param trait_sd Between-unit standard deviation of the derived trait.
#' @param n_unit Units per group.
#' @param alpha Type-I error rate.
#' @param n_sim Number of Monte Carlo replicates.
#' @param alternative `"two.sided"`, `"greater"`, or `"less"`.
#' @param seed Optional seed.
#' @return An `agri_growth_power` object.
#' @export
#'
#' @examples
#' growth_power(effect=5, trait_sd=8, n_unit=20, n_sim=500, seed=1)
#' growth_power(effect=5, trait_sd=8, n_unit=40, n_sim=500, seed=1)
#' growth_power(effect=8, trait_sd=8, n_unit=20, n_sim=500, alternative="greater", seed=2)
growth_power <- function(effect, trait_sd, n_unit, alpha = 0.05, n_sim = 5000L,
                         alternative = c("two.sided", "greater", "less"), seed = NULL) {
  alternative <- match.arg(alternative); n_unit <- as.integer(n_unit); n_sim <- as.integer(n_sim)
  if (!is.numeric(effect) || length(effect)!=1L || !is.finite(effect)) stop("`effect` must be finite.", call. = FALSE)
  if (!is.numeric(trait_sd) || length(trait_sd)!=1L || !is.finite(trait_sd) || trait_sd <= 0) stop("`trait_sd` must be positive.", call. = FALSE)
  if (n_unit < 2L || n_sim < 100L) stop("Use at least two units per group and at least 100 simulations.", call. = FALSE)
  if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1) stop("`alpha` must lie between 0 and 1.", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)
  hit <- logical(n_sim); estimates <- numeric(n_sim)
  for (i in seq_len(n_sim)) {
    c0 <- stats::rnorm(n_unit, 0, trait_sd); tr <- stats::rnorm(n_unit, effect, trait_sd)
    estimates[i] <- mean(tr)-mean(c0)
    p <- stats::t.test(tr, c0, alternative=alternative, var.equal=FALSE)$p.value
    hit[i] <- is.finite(p) && p < alpha
  }
  out <- list(power=mean(hit), monte_carlo_se=sqrt(mean(hit)*(1-mean(hit))/n_sim), effect=effect, trait_sd=trait_sd, n_unit=n_unit, alpha=alpha, n_sim=n_sim, alternative=alternative, estimated_effect_mean=mean(estimates))
  class(out) <- "agri_growth_power"
  out
}

#' @export
print.agri_growth_multiphase <- function(x, ...) {
  cat("<agri_growth_multiphase>", x$n_phases, "phase(s)\n")
  print(x$components, row.names = FALSE)
  cat("RSS:", .agf_fmt(x$rss), " sigma:", .agf_fmt(x$sigma), "\n")
  invisible(x)
}

#' @export
print.agri_growth_multiphase_collection <- function(x, ...) {
  cat("<agri_growth_multiphase_collection> group:", x$group, " phases:", x$n_phases, "\n")
  cat("Groups:", paste(x$groups, collapse=", "), "\n")
  invisible(x)
}

#' @export
print.agri_growth_changepoint <- function(x, ...) {
  cat("<agri_growth_changepoint> breakpoint:", .agf_fmt(x$breakpoint), "\n")
  cat("Slope before:", .agf_fmt(x$slope_before), " slope after:", .agf_fmt(x$slope_after), "\n")
  invisible(x)
}

#' @export
print.agri_growth_event <- function(x, ...) {
  cat("<agri_growth_event>", x$event_type, "at time", .agf_fmt(x$event_time), "\n")
  invisible(x)
}

#' @export
print.agri_growth_defoliation <- function(x, ...) {
  cat("<agri_growth_defoliation>", nrow(x$parameters), "fitted unit(s)\n")
  print(x$parameters, row.names=FALSE)
  invisible(x)
}

#' @export
print.agri_growth_density <- function(x, ...) {
  cat("<agri_growth_density> reciprocal size-density model\n")
  print(summary(x$fit)$coefficients)
  invisible(x)
}

#' @export
print.agri_growth_competition <- function(x, ...) {
  cat("<agri_growth_competition>", length(x$initial_size), "plants;", length(unique(x$trajectory$time)), "output times\n")
  invisible(x)
}

#' @export
print.agri_growth_harvest <- function(x, ...) {
  cat("<agri_growth_harvest> optimum time:", .agf_fmt(x$optimum_time), " response:", .agf_fmt(x$response), " net value:", .agf_fmt(x$net_value), "\n")
  invisible(x)
}

#' @export
print.agri_growth_power <- function(x, ...) {
  cat("<agri_growth_power> power:", .agf_fmt(x$power), " Monte Carlo SE:", .agf_fmt(x$monte_carlo_se), "\n")
  invisible(x)
}
