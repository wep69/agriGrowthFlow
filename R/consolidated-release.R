.agf_release_roles <- function(x, time = NULL, response = NULL, unit = NULL, group = NULL) {
  if (inherits(x, "agri_growth_data")) {
    data <- x$data
    time <- time %||% .agf_role(x, "time")
    response <- response %||% .agf_role(x, "total_mass")
    unit <- unit %||% .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot") %||% .agf_role(x, "plant")
    group <- group %||% .agf_role(x, "treatment")
    sampling <- x$sampling
  } else {
    .agf_assert_data_frame(x)
    data <- x
    sampling <- "unspecified"
  }
  .agf_assert_column(data, time, "time", allow_null = FALSE)
  .agf_assert_column(data, response, "response", allow_null = TRUE)
  .agf_assert_column(data, unit, "unit", allow_null = TRUE)
  .agf_assert_column(data, group, "group", allow_null = TRUE)
  list(data = data, time = time, response = response, unit = unit, group = group, sampling = sampling)
}

.agf_release_backend <- function(package) {
  if (identical(package, "base")) return(TRUE)
  requireNamespace(package, quietly = TRUE)
}

.agf_release_guide_row <- function(method, suitability, priority, backend, rationale, minimum_requirement) {
  data.frame(
    method = method,
    suitability = suitability,
    priority = as.integer(priority),
    backend = backend,
    backend_available = .agf_release_backend(backend),
    rationale = rationale,
    minimum_requirement = minimum_requirement,
    stringsAsFactors = FALSE
  )
}

#' Design-aware guide to plant-growth analysis families
#'
#' @description
#' `growth_method_guide()` creates a transparent shortlist of analysis families from
#' the declared sampling structure, temporal support, scientific objective, and
#' optional backend availability. Priorities are navigation aids, not model
#' probabilities or evidence that one method is uniquely correct.
#'
#' @param x An `agri_growth_data` object or a data frame.
#' @param time,response,unit,group Optional role columns. Roles are inherited from
#'   `growth_data()` when possible.
#' @param objective Scientific objective: trajectory description, rates, treatment
#'   comparison, uncertainty, phases, or decision support.
#' @param include_optional If `FALSE`, methods whose optional backend is unavailable
#'   are omitted from the returned guide.
#'
#' @return An `agri_growth_method_guide` data frame.
#' @export
#'
#' @examples
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", treatment = "nitrogen",
#'                  total_mass = "total_mass_g", leaf_area = "leaf_area_m2")
#' growth_method_guide(g, objective = "rates")
#' growth_method_guide(g, objective = "trajectory")
#' b <- growth_example_data("bean_repeated")
#' growth_method_guide(b, time = "day", response = "height_cm",
#'                     unit = "plant_id", group = "water_regime",
#'                     objective = "treatment_comparison")
growth_method_guide <- function(x,
                                time = NULL,
                                response = NULL,
                                unit = NULL,
                                group = NULL,
                                objective = c("trajectory", "rates", "treatment_comparison", "uncertainty", "phases", "decision"),
                                include_optional = TRUE) {
  objective <- match.arg(objective)
  rr <- .agf_release_roles(x, time, response, unit, group)
  tv <- rr$data[[rr$time]]
  n_times <- length(unique(tv[!is.na(tv)]))
  n_units <- if (is.null(rr$unit)) NA_integer_ else length(unique(rr$data[[rr$unit]][!is.na(rr$data[[rr$unit]])]))
  n_groups <- if (is.null(rr$group)) 1L else length(unique(rr$data[[rr$group]][!is.na(rr$data[[rr$group]])]))
  repeated_like <- rr$sampling %in% c("repeated", "mixed") || (!is.null(rr$unit) && n_units > 1L)

  rows <- list()
  add <- function(...) rows[[length(rows) + 1L]] <<- .agf_release_guide_row(...)

  classical_ok <- inherits(x, "agri_growth_data") && !is.null(.agf_role(x, "total_mass"))
  add(
    "classical",
    if (classical_ok) "suitable" else "conditional",
    if (objective == "rates") 1L else 5L,
    "base",
    if (objective == "rates") "Interval rates and classical growth indices directly address the declared objective." else "Classical indices complement trajectory models when the required biological roles are declared.",
    "A persistent interval unit, at least two times, and the biological variables required by the requested index."
  )

  add(
    "parametric",
    if (n_times >= 4L && !is.null(rr$response)) "suitable" else "conditional",
    if (objective %in% c("trajectory", "uncertainty", "decision")) 1L else 3L,
    "base",
    "Biologically interpretable sigmoid or crop-growth functions provide compact trajectory traits when their shape is supported by the data.",
    "At least four distinct times, a numeric response, plausible model shape, convergence, and diagnostic review."
  )

  add(
    "mixed",
    if (repeated_like && !is.null(rr$unit) && n_times >= 3L) "suitable" else "conditional",
    if (objective == "treatment_comparison" && repeated_like) 1L else 4L,
    "nlme",
    "Mixed-effects growth curves preserve persistent-unit trajectories and can model residual correlation and heterogeneous variance.",
    "A persistent unit observed repeatedly, adequate time support, and the optional nlme backend."
  )

  add(
    "smooth",
    if (n_times >= 4L && !is.null(rr$response)) "suitable" else "conditional",
    if (objective == "trajectory") 2L else 4L,
    "base",
    "Flexible smoothers describe trajectory shape and derivatives without imposing one named parametric curve.",
    "At least four distinct times; inferential dependence still requires a design-aware model when observations are longitudinal."
  )

  add(
    "multiphase",
    if (n_times >= 6L && !is.null(rr$response)) "suitable" else "conditional",
    if (objective == "phases") 1L else 6L,
    "base",
    "Ordered sums of logistic phases are available when a single uninterrupted sigmoid is biologically inadequate.",
    "Rich temporal support, evidence for multiple phases, stable multistart optimization, and interpretation of the complete summed trajectory."
  )

  add(
    "bootstrap",
    if (!is.null(rr$response) && n_times >= 4L) "suitable" else "conditional",
    if (objective == "uncertainty") 1L else 7L,
    "base",
    "Design-aware resampling propagates nonlinear refitting uncertainty to coefficients and biological traits.",
    "A fitted single parametric trajectory and a resampling unit consistent with the experimental design."
  )

  add(
    "bayesian",
    if (!is.null(rr$response) && n_times >= 4L) "suitable" else "conditional",
    if (objective == "uncertainty") 2L else 8L,
    "brms",
    "Bayesian nonlinear hierarchy propagates parameter uncertainty and can place treatment or persistent-unit effects on biological curve parameters.",
    "Supported Logistic, Gompertz, or Richards model; priors; brms/Stan; predictive checks; and MCMC diagnostics."
  )

  add(
    "functional",
    if (!is.null(rr$unit) && n_times >= 4L) "conditional" else "not_recommended",
    9L,
    "base",
    "Functional summaries are useful when whole trajectories are scientific objects, but require careful handling of common or irregular temporal support.",
    "Multiple persistent units with sufficient time support; optional refund or fdapace backends expand irregular-data options."
  )

  out <- do.call(rbind, rows)
  if (!isTRUE(include_optional)) out <- out[out$backend_available, , drop = FALSE]
  out <- out[order(out$priority, match(out$suitability, c("suitable", "conditional", "not_recommended")), out$method), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "objective") <- objective
  attr(out, "n_times") <- n_times
  attr(out, "n_units") <- n_units
  attr(out, "n_groups") <- n_groups
  attr(out, "sampling") <- rr$sampling
  class(out) <- c("agri_growth_method_guide", "data.frame")
  out
}

#' @export
print.agri_growth_method_guide <- function(x, ...) {
  cat("<agri_growth_method_guide> objective:", attr(x, "objective") %||% "unspecified", "\n")
  cat("Times:", attr(x, "n_times") %||% NA_integer_, " Units:", attr(x, "n_units") %||% NA_integer_, " Sampling:", attr(x, "sampling") %||% "unspecified", "\n")
  print.data.frame(x, row.names = FALSE)
  invisible(x)
}

.agf_release_auto_strategy <- function(guide, objective) {
  core <- guide[guide$method %in% c("classical", "parametric", "mixed", "smooth", "multiphase") & guide$suitability != "not_recommended" & guide$backend_available, , drop = FALSE]
  if (!nrow(core)) return("parametric")
  if (objective == "rates" && "classical" %in% core$method) return("classical")
  if (objective == "phases" && "multiphase" %in% core$method) return("multiphase")
  core$method[[which.min(core$priority)]]
}

.agf_release_comparison <- function(core) {
  if (inherits(core, "agri_growth_fit_set")) return(growth_compare(core))
  if (inherits(core, "agri_growth_fit_collection")) {
    rows <- lapply(names(core$fits), function(g) {
      z <- core$fits[[g]]
      if (!inherits(z, "agri_growth_fit_set")) return(NULL)
      a <- growth_compare(z)
      a$group <- g
      a
    })
    rows <- Filter(Negate(is.null), rows)
    if (!length(rows)) return(NULL)
    ans <- do.call(rbind, rows)
    rownames(ans) <- NULL
    return(ans)
  }
  NULL
}

.agf_release_param_diagnostics <- function(core, comparison = NULL) {
  if (inherits(core, "agri_growth_fit")) return(growth_diagnose(core))
  if (inherits(core, "agri_growth_fit_set")) {
    return(lapply(core$fits, growth_diagnose))
  }
  if (inherits(core, "agri_growth_fit_collection")) {
    return(lapply(core$fits, function(z) {
      if (inherits(z, "agri_growth_fit")) return(growth_diagnose(z))
      if (inherits(z, "agri_growth_fit_set")) return(lapply(z$fits, growth_diagnose))
      NULL
    }))
  }
  NULL
}

.agf_release_single_fit <- function(core, comparison = NULL) {
  if (inherits(core, "agri_growth_fit")) return(core)
  if (inherits(core, "agri_growth_fit_set")) {
    if (!is.null(comparison) && nrow(comparison)) {
      model <- comparison$model[[1L]]
      return(core$fits[[model]])
    }
    return(core$fits[[1L]])
  }
  NULL
}

#' Run or freeze an auditable consolidated plant-growth workflow
#'
#' @description
#' `growth_workflow()` connects design validation, method guidance, one explicit core
#' strategy, diagnostics, candidate comparison, biological traits, and an optional
#' uncertainty layer. `strategy = "auto"` is deliberately conservative and records
#' the decision rule. It does not establish that the selected method is uniquely
#' correct. Use `execute = FALSE` to freeze the analysis contract before fitting.
#'
#' @param x An `agri_growth_data` object or a data frame.
#' @param time,response,unit,group Optional role columns.
#' @param objective Scientific objective.
#' @param strategy Core strategy or `"auto"`.
#' @param models Candidate parametric models.
#' @param n_start Number of starts for parametric or multiphase optimization.
#' @param smooth_method Flexible smoother.
#' @param mixed_degree Fixed polynomial degree for `growth_mixed()`.
#' @param uncertainty Optional uncertainty layer.
#' @param bootstrap_R Bootstrap replicates when requested.
#' @param uncertainty_args Named list passed only to the uncertainty engine.
#' @param seed Optional reproducibility seed.
#' @param execute If `FALSE`, record the complete plan without fitting.
#' @param ... Additional arguments forwarded only to the selected core strategy.
#'
#' @return An `agri_growth_workflow` object.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' growth_workflow(d, time = "day", response = "biomass_g", execute = FALSE)
#' growth_workflow(d, time = "day", response = "biomass_g",
#'                 strategy = "parametric", models = c("logistic", "gompertz"),
#'                 n_start = 3, seed = 1)
#' b <- growth_example_data("bean_repeated")
#' growth_workflow(b, time = "day", response = "height_cm", unit = "plant_id",
#'                 group = "water_regime", strategy = "smooth")
growth_workflow <- function(x,
                            time = NULL,
                            response = NULL,
                            unit = NULL,
                            group = NULL,
                            objective = c("trajectory", "rates", "treatment_comparison", "uncertainty", "phases", "decision"),
                            strategy = c("auto", "classical", "parametric", "mixed", "smooth", "multiphase"),
                            models = c("logistic", "gompertz", "richards"),
                            n_start = 10L,
                            smooth_method = c("smooth_spline", "loess", "gam", "scam"),
                            mixed_degree = 2L,
                            uncertainty = c("none", "auto", "bootstrap", "bayesian"),
                            bootstrap_R = 999L,
                            uncertainty_args = list(),
                            seed = NULL,
                            execute = TRUE,
                            ...) {
  objective <- match.arg(objective)
  strategy_requested <- match.arg(strategy)
  smooth_method <- match.arg(smooth_method)
  uncertainty_requested <- match.arg(uncertainty)
  if (!is.list(uncertainty_args)) stop("`uncertainty_args` must be a named list.", call. = FALSE)
  if (length(uncertainty_args) && (is.null(names(uncertainty_args)) || any(!nzchar(names(uncertainty_args))))) {
    stop("Every element of `uncertainty_args` must be named.", call. = FALSE)
  }
  rr <- .agf_release_roles(x, time, response, unit, group)
  if (is.null(rr$response) && strategy_requested != "classical") {
    stop("A response column is required for trajectory workflows. Supply `response` or declare `total_mass` with growth_data().", call. = FALSE)
  }

  validation <- if (inherits(x, "agri_growth_data")) growth_validate(x, strict = FALSE) else NULL
  plan <- if (inherits(x, "agri_growth_data")) growth_plan(x) else NULL
  guide <- growth_method_guide(x, time = rr$time, response = rr$response, unit = rr$unit,
                               group = rr$group, objective = objective, include_optional = TRUE)
  selected <- if (identical(strategy_requested, "auto")) .agf_release_auto_strategy(guide, objective) else strategy_requested
  if (identical(selected, "mixed") && !requireNamespace("nlme", quietly = TRUE)) {
    stop("The selected mixed strategy requires the optional `nlme` backend.", call. = FALSE)
  }
  decision <- data.frame(
    stage = c("objective", "strategy", "execution", "uncertainty"),
    decision = c(objective, selected, if (isTRUE(execute)) "execute" else "plan_only", uncertainty_requested),
    rationale = c(
      "Scientific objective supplied by the analyst.",
      if (identical(strategy_requested, "auto")) "Selected by the transparent design/objective priority rules in growth_method_guide()." else "Core strategy explicitly supplied by the analyst.",
      if (isTRUE(execute)) "Model fitting requested." else "Planning-only mode requested; no core model is fitted.",
      "Uncertainty layer is isolated from core-model arguments through uncertainty_args."
    ),
    stringsAsFactors = FALSE
  )

  out <- list(
    input = x,
    roles = list(time = rr$time, response = rr$response, unit = rr$unit, group = rr$group),
    objective = objective,
    validation = validation,
    plan = plan,
    guide = guide,
    decision_ledger = decision,
    strategy_requested = strategy_requested,
    selected_strategy = selected,
    core = NULL,
    diagnostics = NULL,
    comparison = NULL,
    traits = NULL,
    uncertainty = NULL,
    uncertainty_method = "none",
    notes = character(),
    seed = seed,
    executed = isTRUE(execute),
    package_version = "1.0.0"
  )
  class(out) <- "agri_growth_workflow"
  if (!isTRUE(execute)) {
    out$notes <- c(out$notes, "Planning-only workflow: no model was fitted and no inferential result should be reported from this object.")
    return(out)
  }
  if (!is.null(validation) && identical(validation$status, "error")) {
    stop("The declared growth-data structure contains error-level validation issues. Resolve them before executing the consolidated workflow.", call. = FALSE)
  }
  dots <- list(...)
  if (!is.null(seed)) set.seed(seed)

  if (identical(selected, "classical")) {
    if (inherits(x, "agri_growth_data")) {
      args <- c(list(x = x, unit = rr$unit, by = rr$group), dots)
    } else {
      args <- c(list(x = x, time = rr$time, total_mass = rr$response, unit = rr$unit, by = rr$group), dots)
    }
    out$core <- do.call(growth_classical, args)
    out$traits <- out$core$intervals
  } else if (identical(selected, "parametric")) {
    args <- c(list(x = x, model = models, time = rr$time, response = rr$response,
                   group = rr$group, n_start = n_start, seed = seed), dots)
    out$core <- do.call(growth_fit, args)
    out$comparison <- .agf_release_comparison(out$core)
    out$traits <- growth_traits(out$core)
    out$diagnostics <- .agf_release_param_diagnostics(out$core, out$comparison)
  } else if (identical(selected, "mixed")) {
    args <- c(list(x = x, time = rr$time, response = rr$response, unit = rr$unit,
                   group = rr$group, degree = mixed_degree), dots)
    out$core <- do.call(growth_mixed, args)
    out$diagnostics <- growth_mixed_diagnose(out$core)
  } else if (identical(selected, "smooth")) {
    args <- c(list(x = x, time = rr$time, response = rr$response, unit = rr$unit,
                   group = rr$group, method = smooth_method), dots)
    out$core <- do.call(growth_smooth, args)
    out$traits <- growth_smooth_traits(out$core)
  } else if (identical(selected, "multiphase")) {
    args <- c(list(x = x, time = rr$time, response = rr$response, group = rr$group,
                   n_phases = 2L, n_start = n_start, seed = seed), dots)
    out$core <- do.call(growth_multiphase, args)
    if (inherits(out$core, "agri_growth_multiphase")) {
      out$traits <- growth_stability(out$core)
    } else {
      out$notes <- c(out$notes, "Grouped multiphase fits are retained as a collection; stability points should be extracted explicitly within each group.")
    }
  }

  unc <- uncertainty_requested
  if (identical(unc, "auto")) {
    unc <- if (objective == "uncertainty" && selected == "parametric") "bootstrap" else "none"
  }
  if (identical(unc, "bootstrap")) {
    one <- .agf_release_single_fit(out$core, out$comparison)
    if (is.null(one)) {
      out$notes <- c(out$notes, "Bootstrap was not attached automatically because the core object is not one single parametric fit. Resample groups or models explicitly.")
    } else {
      ua <- uncertainty_args
      if (is.null(ua$R)) ua$R <- bootstrap_R
      if (is.null(ua$seed)) ua$seed <- seed
      out$uncertainty <- do.call(growth_boot, c(list(object = one), ua))
      out$uncertainty_method <- "bootstrap"
    }
  } else if (identical(unc, "bayesian")) {
    if (selected != "parametric") {
      stop("The 1.0.0 Bayesian convenience layer is attached to a supported parametric core. Select `strategy = \"parametric\"` or call growth_bayes() explicitly.", call. = FALSE)
    }
    one <- .agf_release_single_fit(out$core, out$comparison)
    model_use <- if (!is.null(one)) one$model else .agf_model_alias(models[[1L]])
    if (!model_use %in% c("logistic", "gompertz", "richards")) {
      stop("The Bayesian convenience layer supports Logistic, Gompertz, and Richards models only.", call. = FALSE)
    }
    ua <- uncertainty_args
    if (is.null(ua$seed)) ua$seed <- seed
    out$uncertainty <- do.call(growth_bayes, c(list(x = x, model = model_use, time = rr$time,
                                                    response = rr$response, group = rr$group, unit = rr$unit), ua))
    out$uncertainty_method <- "bayesian"
  }

  if (identical(out$uncertainty_method, "none") && objective == "uncertainty") {
    out$notes <- c(out$notes, "No uncertainty engine was executed. Add design-aware bootstrap or Bayesian inference before making uncertainty claims.")
  }
  out$notes <- unique(out$notes)
  out
}

#' @export
print.agri_growth_workflow <- function(x, ...) {
  cat("<agri_growth_workflow> agriGrowthFlow", x$package_version %||% "1.0.0", "\n")
  cat("Objective:", x$objective, " Strategy:", x$selected_strategy, " Executed:", x$executed, "\n")
  cat("Uncertainty:", x$uncertainty_method, " Seed:", if (is.null(x$seed)) "not set" else x$seed, "\n")
  if (length(x$notes)) cat("Notes:", paste(x$notes, collapse = " | "), "\n")
  invisible(x)
}

#' @export
summary.agri_growth_workflow <- function(object, ...) {
  out <- list(
    objective = object$objective,
    selected_strategy = object$selected_strategy,
    executed = object$executed,
    validation_status = if (is.null(object$validation)) "not_declared" else object$validation$status,
    has_core = !is.null(object$core),
    has_diagnostics = !is.null(object$diagnostics),
    has_comparison = !is.null(object$comparison),
    has_traits = !is.null(object$traits),
    uncertainty_method = object$uncertainty_method,
    has_uncertainty = !is.null(object$uncertainty),
    seed = object$seed,
    notes = object$notes
  )
  class(out) <- "summary.agri_growth_workflow"
  out
}

#' Audit a consolidated growth workflow
#'
#' @param object An `agri_growth_workflow` object.
#' @return A data frame with PASS, INFO, or FAIL gates.
#' @export
growth_workflow_audit <- function(object) {
  if (!inherits(object, "agri_growth_workflow")) stop("`object` must be an `agri_growth_workflow`.", call. = FALSE)
  rows <- list()
  add <- function(gate, status, detail) rows[[length(rows) + 1L]] <<- data.frame(gate = gate, status = status, detail = detail, stringsAsFactors = FALSE)
  if (is.null(object$validation)) add("declared_design_validation", "INFO", "Input was a plain data frame; no growth_data() design contract was available.")
  else if (identical(object$validation$status, "error")) add("declared_design_validation", "FAIL", "Validation contains error-level issues.")
  else add("declared_design_validation", "PASS", paste("Validation status:", object$validation$status))
  add("selected_strategy", if (nzchar(object$selected_strategy)) "PASS" else "FAIL", paste("Selected strategy:", object$selected_strategy))
  add("execution", if (isTRUE(object$executed)) "PASS" else "INFO", if (isTRUE(object$executed)) "Core analysis execution was requested." else "Planning-only workflow; no fitting was requested.")
  add("core_object", if (!isTRUE(object$executed)) "INFO" else if (!is.null(object$core)) "PASS" else "FAIL", if (is.null(object$core)) "No core object is stored." else paste("Core class:", paste(class(object$core), collapse = ", ")))
  add("diagnostics", if (!isTRUE(object$executed)) "INFO" else if (!is.null(object$diagnostics)) "PASS" else "INFO", if (is.null(object$diagnostics)) "No generic diagnostic object is stored for this strategy." else "Diagnostic output is stored.")
  add("candidate_comparison", if (!is.null(object$comparison)) "PASS" else "INFO", if (is.null(object$comparison)) "No same-observation candidate comparison is stored." else "Candidate comparison is stored.")
  add("uncertainty", if (!is.null(object$uncertainty)) "PASS" else "INFO", if (is.null(object$uncertainty)) "No uncertainty object is attached." else paste("Uncertainty method:", object$uncertainty_method))
  add("seed", if (is.null(object$seed)) "INFO" else "PASS", if (is.null(object$seed)) "No seed was recorded." else paste("Seed:", object$seed))
  add("workflow_notes", "INFO", if (length(object$notes)) paste(object$notes, collapse = " | ") else "No additional workflow notes.")
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

.agf_release_coef_table <- function(object) {
  if (inherits(object, "agri_growth_fit")) {
    return(data.frame(term = names(object$coefficients), estimate = as.numeric(object$coefficients), model = object$model, stringsAsFactors = FALSE))
  }
  if (inherits(object, "agri_growth_fit_set")) {
    ans <- do.call(rbind, lapply(names(object$fits), function(m) .agf_release_coef_table(object$fits[[m]])))
    rownames(ans) <- NULL
    return(ans)
  }
  if (inherits(object, "agri_growth_allometry")) {
    z <- stats::coef(object$fit)
    return(data.frame(term = names(z), estimate = as.numeric(z), stringsAsFactors = FALSE))
  }
  stop("Coefficient extraction is not standardized for this object class.", call. = FALSE)
}

.agf_release_diagnostic_table <- function(object) {
  if (inherits(object, "agri_growth_diagnostics")) return(object$summary)
  if (inherits(object, "agri_growth_mixed_diagnostics")) {
    return(data.frame(
      n = object$n, n_units = object$n_units, residual_sd = object$residual_sd,
      shapiro_p = object$shapiro_p, median_within_unit_lag1 = object$median_within_unit_lag1,
      aic = object$aic, bic = object$bic, stringsAsFactors = FALSE
    ))
  }
  if (inherits(object, "agri_growth_bayes_diagnostics")) {
    if (!is.null(object$summary) && is.data.frame(object$summary)) return(object$summary)
    vals <- object[vapply(object, function(z) length(z) == 1L && (is.numeric(z) || is.character(z) || is.logical(z)), logical(1))]
    return(as.data.frame(vals, stringsAsFactors = FALSE))
  }
  stop("Diagnostic extraction is not standardized for this object class.", call. = FALSE)
}

#' Standardize common agriGrowthFlow results as data frames
#'
#' @param object A supported package object.
#' @param component Requested result view. `"auto"` chooses a conservative class-specific view.
#' @return A data frame.
#' @export
growth_table <- function(object, component = c("auto", "audit", "traits", "comparison", "diagnostics", "intervals", "coefficients", "guide")) {
  component <- match.arg(component)
  if (inherits(object, "agri_growth_workflow")) {
    if (component == "auto") component <- "audit"
    if (component == "audit") return(growth_workflow_audit(object))
    if (component == "guide") return(as.data.frame(object$guide))
    if (component == "traits") {
      if (is.null(object$traits)) stop("The workflow does not contain a standardized traits table.", call. = FALSE)
      return(as.data.frame(object$traits))
    }
    if (component == "comparison") {
      if (is.null(object$comparison)) stop("The workflow does not contain a candidate comparison.", call. = FALSE)
      return(as.data.frame(object$comparison))
    }
    if (component == "diagnostics") {
      if (is.null(object$diagnostics)) stop("The workflow does not contain a single standardized diagnostic object.", call. = FALSE)
      if (is.list(object$diagnostics) && !inherits(object$diagnostics, c("agri_growth_diagnostics", "agri_growth_mixed_diagnostics", "agri_growth_bayes_diagnostics"))) {
        stop("Workflow diagnostics are nested by model or group; extract the desired diagnostic object explicitly before tabulation.", call. = FALSE)
      }
      return(.agf_release_diagnostic_table(object$diagnostics))
    }
    if (component == "intervals") return(growth_table(object$core, component = "intervals"))
    if (component == "coefficients") return(growth_table(object$core, component = "coefficients"))
  }
  if (inherits(object, "agri_growth_method_guide")) return(as.data.frame(object))
  if (inherits(object, "agri_growth_comparison")) return(as.data.frame(object))
  if (inherits(object, "agri_growth_validation")) return(object$issues)
  if (inherits(object, "agri_growth_indices")) return(object$intervals)
  if (inherits(object, c("agri_growth_fit", "agri_growth_fit_set", "agri_growth_allometry"))) {
    if (component %in% c("auto", "coefficients")) return(.agf_release_coef_table(object))
    if (component == "traits" && inherits(object, c("agri_growth_fit", "agri_growth_fit_set"))) return(growth_traits(object))
  }
  if (inherits(object, "agri_growth_smooth") || inherits(object, "agri_growth_smooth_collection")) {
    return(growth_smooth_traits(object))
  }
  if (inherits(object, "agri_growth_boot")) {
    return(growth_boot_traits(object))
  }
  if (inherits(object, c("agri_growth_diagnostics", "agri_growth_mixed_diagnostics", "agri_growth_bayes_diagnostics"))) {
    return(.agf_release_diagnostic_table(object))
  }
  if (is.data.frame(object)) return(object)
  stop("No standardized table view is available for this object and component.", call. = FALSE)
}

.agf_md_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\|", "\\\\|", x)
  gsub("[\r\n]+", " ", x)
}

.agf_md_table <- function(x, digits = 4L, max_rows = 20L) {
  if (!is.data.frame(x) || !ncol(x)) return("_No tabular output._")
  z <- utils::head(x, max_rows)
  z[] <- lapply(z, function(v) {
    if (is.numeric(v)) format(round(v, digits), trim = TRUE, scientific = FALSE) else .agf_md_escape(v)
  })
  header <- paste0("| ", paste(.agf_md_escape(names(z)), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(z)), collapse = " | "), " |")
  body <- apply(z, 1L, function(r) paste0("| ", paste(.agf_md_escape(r), collapse = " | "), " |"))
  c(header, sep, body)
}

#' Create a concise reproducible Markdown analysis record
#'
#' @param object An `agri_growth_workflow` object.
#' @param file Optional output `.md` path. When `NULL`, text is returned only.
#' @param title Report title.
#' @param digits Number of displayed decimal places.
#' @return A character vector containing Markdown. Invisibly writes the same content when `file` is supplied.
#' @export
growth_report <- function(object, file = NULL, title = "agriGrowthFlow analysis report", digits = 4L) {
  if (!inherits(object, "agri_growth_workflow")) stop("`object` must be an `agri_growth_workflow`.", call. = FALSE)
  audit <- growth_workflow_audit(object)
  lines <- c(
    paste0("# ", title), "",
    "## Analysis contract", "",
    paste0("- agriGrowthFlow release: ", object$package_version %||% "1.0.0"),
    paste0("- Objective: ", object$objective),
    paste0("- Selected strategy: ", object$selected_strategy),
    paste0("- Executed: ", object$executed),
    paste0("- Uncertainty method: ", object$uncertainty_method),
    paste0("- Seed: ", if (is.null(object$seed)) "not recorded" else object$seed), "",
    "## Workflow audit", "", .agf_md_table(audit, digits = digits), ""
  )
  if (!is.null(object$comparison)) {
    lines <- c(lines, "## Candidate comparison", "", .agf_md_table(as.data.frame(object$comparison), digits = digits), "")
  }
  if (!is.null(object$traits) && is.data.frame(object$traits)) {
    lines <- c(lines, "## Biological traits", "", .agf_md_table(object$traits, digits = digits), "")
  }
  if (length(object$notes)) {
    lines <- c(lines, "## Workflow notes", "", paste0("- ", object$notes), "")
  }
  lines <- c(lines,
             "## Interpretation safeguards", "",
             "- Method guidance and automatic strategy selection are planning aids, not proof that one model is scientifically correct.",
             "- Candidate information criteria are interpreted only among models fitted to identical prepared observations and are not used as a universal decision rule.",
             "- Destructive subsamples are not treated as independent longitudinal subjects when a persistent experimental unit has been declared.",
             "- Uncertainty claims require an uncertainty object and appropriate diagnostic review.",
             "- This report records the analysis contract and does not generate unsupported treatment-effect or causal claims.", "")
  if (!is.null(file)) {
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    writeLines(lines, con = file, useBytes = TRUE)
  }
  lines
}

#' Export complete or tabular agriGrowthFlow results
#'
#' @param object A supported package object, preferably an `agri_growth_workflow`.
#' @param path Output file for `rds`/`csv` or output directory for `bundle`.
#' @param format One of `"rds"`, `"csv"`, or `"bundle"`.
#' @param overwrite Whether an existing target may be replaced.
#' @return Invisibly, the normalized output path.
#' @export
growth_export <- function(object, path, format = c("rds", "csv", "bundle"), overwrite = FALSE) {
  format <- match.arg(format)
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) stop("`path` must be one non-empty path.", call. = FALSE)
  exists <- file.exists(path) || dir.exists(path)
  if (exists && !isTRUE(overwrite)) stop("Output target already exists; use `overwrite = TRUE` to replace it.", call. = FALSE)

  if (format == "rds") {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(object, path)
    return(invisible(normalizePath(path, winslash = "/", mustWork = TRUE)))
  }
  if (format == "csv") {
    tab <- growth_table(object)
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(tab, path, row.names = FALSE, na = "")
    return(invisible(normalizePath(path, winslash = "/", mustWork = TRUE)))
  }

  if (exists && isTRUE(overwrite)) unlink(path, recursive = TRUE, force = TRUE)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(path)) stop("Could not create bundle output directory.", call. = FALSE)
  saveRDS(object, file.path(path, "object.rds"))
  if (inherits(object, "agri_growth_workflow")) {
    utils::write.csv(growth_workflow_audit(object), file.path(path, "workflow_audit.csv"), row.names = FALSE, na = "")
    utils::write.csv(as.data.frame(object$guide), file.path(path, "method_guide.csv"), row.names = FALSE, na = "")
    if (!is.null(object$traits) && is.data.frame(object$traits)) utils::write.csv(object$traits, file.path(path, "traits.csv"), row.names = FALSE, na = "")
    if (!is.null(object$comparison)) utils::write.csv(as.data.frame(object$comparison), file.path(path, "candidate_comparison.csv"), row.names = FALSE, na = "")
    growth_report(object, file = file.path(path, "report.md"))
  } else {
    utils::write.csv(growth_table(object), file.path(path, "table.csv"), row.names = FALSE, na = "")
  }
  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}
