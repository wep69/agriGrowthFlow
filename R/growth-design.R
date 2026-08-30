#' Declare the experimental design used for a growth dataset
#'
#' @param x An `agri_growth_data` object or a data frame.
#' @param design Design label: `"auto"`, `"crd"`, `"rcbd"`,
#'   `"repeated"`, or `"serial_destructive"`.
#' @param treatment,block,experimental_unit,subject,harvest_unit,phase Optional role columns.
#'   When `x` is an `agri_growth_data` object, omitted roles are inherited when possible.
#' @param metadata Optional named list.
#'
#' @return An `agri_growth_design` object.
#' @export
#'
#' @examples
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", treatment = "nitrogen", block = "block")
#' growth_design(g, design = "rcbd")

growth_design <- function(x,
                          design = c("auto", "crd", "rcbd", "repeated", "serial_destructive"),
                          treatment = NULL,
                          block = NULL,
                          experimental_unit = NULL,
                          subject = NULL,
                          harvest_unit = NULL,
                          phase = NULL,
                          metadata = list()) {
  design <- match.arg(design)
  if (inherits(x, "agri_growth_data")) {
    data <- x$data
    treatment <- treatment %||% .agf_role(x, "treatment")
    block <- block %||% .agf_role(x, "block")
    experimental_unit <- experimental_unit %||% .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot")
    subject <- subject %||% .agf_role(x, "plant")
    sampling <- x$sampling
    time <- .agf_role(x, "time")
  } else {
    .agf_assert_data_frame(x)
    data <- x
    sampling <- "auto"
    time <- NULL
  }

  roles <- list(
    treatment = treatment,
    block = block,
    experimental_unit = experimental_unit,
    subject = subject,
    harvest_unit = harvest_unit,
    phase = phase,
    time = time
  )
  for (nm in names(roles)) {
    .agf_assert_column(data, roles[[nm]], arg = nm, allow_null = TRUE)
  }
  if (!is.list(metadata)) stop("`metadata` must be a named list.", call. = FALSE)

  out <- list(
    data = data,
    design = design,
    sampling = sampling,
    roles = roles,
    metadata = metadata,
    growth_data = if (inherits(x, "agri_growth_data")) x else NULL
  )
  class(out) <- "agri_growth_design"
  out
}

#' @export
print.agri_growth_design <- function(x, ...) {
  cat("<agri_growth_design>\n")
  cat("Design:", x$design, "\n")
  cat("Sampling:", x$sampling, "\n")
  if (!is.null(x$roles$experimental_unit)) cat("Experimental unit:", x$roles$experimental_unit, "\n")
  if (!is.null(x$roles$subject)) cat("Subject/plant:", x$roles$subject, "\n")
  if (!is.null(x$roles$block)) cat("Block:", x$roles$block, "\n")
  invisible(x)
}

#' Validate plant-growth data and design structure
#'
#' @description
#' `growth_validate()` checks data support, role consistency, sampling declarations,
#' and common design errors before growth indices are calculated. It does not prove
#' that a design is valid; it makes declared assumptions and detectable conflicts visible.
#'
#' @param x An `agri_growth_data` or `agri_growth_design` object.
#' @param strict If `TRUE`, stop when any error-level issue is found.
#' @param min_times Minimum distinct times required for interval analysis.
#' @param desirable_times Desirable number of harvest times for a growth phase.
#' @param tolerance Numerical tolerance used in closure and constancy checks.
#'
#' @return An `agri_growth_validation` object.
#' @export

growth_validate <- function(x, strict = FALSE, min_times = 2L, desirable_times = 4L, tolerance = 1e-8) {
  if (inherits(x, "agri_growth_design")) {
    data <- x$data
    gd <- x$growth_data
    roles <- if (!is.null(gd)) gd$roles else x$roles
    roles$experimental_unit <- x$roles$experimental_unit %||% roles$experimental_unit
    roles$plant <- x$roles$subject %||% roles$plant
    sampling <- if (x$sampling == "auto" && !is.null(gd)) gd$sampling else x$sampling
    design <- x$design
  } else if (inherits(x, "agri_growth_data")) {
    data <- x$data
    gd <- x
    roles <- x$roles
    sampling <- x$sampling
    design <- "auto"
  } else {
    stop("`x` must be an agri_growth_data or agri_growth_design object.", call. = FALSE)
  }

  issues <- list()
  time <- roles$time
  if (is.null(time)) {
    issues[[length(issues) + 1L]] <- .agf_issue("error", "missing_time_role", "No time column has been declared.")
  } else {
    tv <- data[[time]]
    if (!is.numeric(tv) && !inherits(tv, c("Date", "POSIXct", "POSIXt"))) {
      issues[[length(issues) + 1L]] <- .agf_issue("error", "time_not_numeric_or_date", "Time must be numeric, Date, or date-time for ordered growth analysis.")
    }
    if (anyNA(tv)) {
      issues[[length(issues) + 1L]] <- .agf_issue("error", "missing_time", "Missing time values were detected.")
    }
    n_times <- length(unique(tv[!is.na(tv)]))
    if (n_times < min_times) {
      issues[[length(issues) + 1L]] <- .agf_issue("error", "too_few_times", paste0("Only ", n_times, " distinct time value(s) were found; at least ", min_times, " are needed for interval growth analysis."))
    } else if (n_times < desirable_times) {
      issues[[length(issues) + 1L]] <- .agf_issue("warning", "limited_time_support", paste0("Only ", n_times, " distinct time values were found. Four or more harvest dates per biological phase are a useful design target when trajectory shape must be characterized."))
    }
  }

  positive_roles <- c("total_mass", "leaf_area", "leaf_mass", "root_mass", "stem_mass", "reproductive_mass", "ground_area")
  for (role in positive_roles) {
    col <- roles[[role]] %||% NULL
    if (!is.null(col)) {
      v <- data[[col]]
      if (!is.numeric(v)) {
        issues[[length(issues) + 1L]] <- .agf_issue("error", paste0(role, "_not_numeric"), paste0("Role `", role, "` maps to a non-numeric column."))
      } else if (any(v < 0, na.rm = TRUE)) {
        issues[[length(issues) + 1L]] <- .agf_issue("error", paste0(role, "_negative"), paste0("Negative values were detected in `", col, "`."))
      } else if (role %in% c("total_mass", "leaf_area", "leaf_mass", "ground_area") && any(v == 0, na.rm = TRUE)) {
        issues[[length(issues) + 1L]] <- .agf_issue("warning", paste0(role, "_zero"), paste0("Zero values in `", col, "` can make logarithmic or ratio-based growth quantities undefined."))
      }
    }
  }

  eu <- roles$experimental_unit %||% roles$plot %||% NULL
  plant <- roles$plant %||% NULL
  treatment <- roles$treatment %||% NULL
  block <- roles$block %||% NULL

  if (!is.null(eu) && anyNA(data[[eu]])) {
    issues[[length(issues) + 1L]] <- .agf_issue("error", "missing_experimental_unit", "Missing experimental-unit identifiers were detected. Interval aggregation cannot preserve the design when the stable unit is unknown.")
  }
  if (!is.null(plant) && anyNA(data[[plant]])) {
    sev <- if (sampling == "repeated") "error" else "warning"
    issues[[length(issues) + 1L]] <- .agf_issue(sev, "missing_plant_id", "Missing plant identifiers were detected in the declared plant column.")
  }
  if (!is.null(block) && anyNA(data[[block]])) {
    issues[[length(issues) + 1L]] <- .agf_issue("warning", "missing_block", "Missing block identifiers were detected. Confirm whether these observations belong to the declared design.")
  }
  if (!is.null(treatment) && anyNA(data[[treatment]])) {
    issues[[length(issues) + 1L]] <- .agf_issue("warning", "missing_treatment", "Missing treatment identifiers were detected. Confirm whether treatment is genuinely undefined for these observations.")
  }

  if (sampling == "repeated") {
    id <- plant %||% eu
    if (is.null(id)) {
      issues[[length(issues) + 1L]] <- .agf_issue("error", "repeated_without_subject", "Repeated sampling requires a stable plant or experimental-unit identifier.")
    } else if (!is.null(time)) {
      key <- data.frame(id = data[[id]], time = data[[time]], stringsAsFactors = FALSE)
      dup <- duplicated(key)
      if (any(dup)) {
        issues[[length(issues) + 1L]] <- .agf_issue("warning", "duplicate_subject_time", "Repeated sampling contains more than one row for at least one subject-time combination. Confirm whether these are technical replicates or duplicated records.")
      }
      counts <- tapply(data[[time]], data[[id]], function(z) length(unique(z[!is.na(z)])))
      if (length(counts) && max(counts, na.rm = TRUE) < 2L) {
        issues[[length(issues) + 1L]] <- .agf_issue("error", "no_subject_repeated", "No declared subject is observed at more than one time.")
      }
    }
  }

  if (sampling == "destructive") {
    if (is.null(eu)) {
      issues[[length(issues) + 1L]] <- .agf_issue("warning", "destructive_without_stable_unit", "Destructive harvest data should identify a stable plot or experimental unit across harvest dates. Different harvested plants are not themselves repeated experimental units.")
    } else if (!is.null(time)) {
      eu_counts <- tapply(data[[time]], data[[eu]], function(z) length(unique(z[!is.na(z)])))
      if (length(eu_counts) && max(eu_counts, na.rm = TRUE) < 2L) {
        issues[[length(issues) + 1L]] <- .agf_issue("error", "no_stable_unit_across_harvests", "No declared experimental unit is represented at more than one harvest date. A serial destructive growth curve requires a higher-level unit, such as a plot, that persists across harvests.")
      }
    }
    if (!is.null(plant) && !is.null(time)) {
      counts <- tapply(data[[time]], data[[plant]], function(z) length(unique(z[!is.na(z)])))
      if (length(counts) && any(counts > 1L, na.rm = TRUE)) {
        issues[[length(issues) + 1L]] <- .agf_issue("warning", "destructive_plant_reappears", "At least one plant identifier appears at multiple times despite destructive sampling. Check the sampling declaration and identifiers.")
      }
    }
  }

  if (sampling == "auto") {
    issues[[length(issues) + 1L]] <- .agf_issue("info", "sampling_not_declared", "Sampling is `auto`. Declare `repeated`, `destructive`, or `mixed` before inferential analysis when the sampling mechanism is known.")
  }

  if (!is.null(eu) && !is.null(treatment)) {
    treatment_count <- tapply(data[[treatment]], data[[eu]], function(z) length(unique(z[!is.na(z)])))
    if (any(treatment_count > 1L, na.rm = TRUE)) {
      issues[[length(issues) + 1L]] <- .agf_issue("warning", "treatment_changes_within_unit", "Treatment changes within at least one declared experimental unit. Confirm whether treatment is time-varying or the unit definition is incorrect.")
    }
  }

  if (!is.null(eu) && !is.null(block)) {
    block_count <- tapply(data[[block]], data[[eu]], function(z) length(unique(z[!is.na(z)])))
    if (any(block_count > 1L, na.rm = TRUE)) {
      issues[[length(issues) + 1L]] <- .agf_issue("error", "block_changes_within_unit", "Block changes within at least one experimental unit.")
    }
  }

  if (design == "rcbd" && is.null(block)) {
    issues[[length(issues) + 1L]] <- .agf_issue("error", "rcbd_without_block", "An RCBD declaration requires a block column.")
  }
  if (design == "repeated" && sampling == "destructive") {
    issues[[length(issues) + 1L]] <- .agf_issue("error", "design_sampling_conflict", "A repeated-measures design conflicts with destructive sampling unless a higher-level experimental unit, rather than harvested plants, is the repeated unit.")
  }
  if (design == "serial_destructive" && sampling == "repeated") {
    issues[[length(issues) + 1L]] <- .agf_issue("error", "design_sampling_conflict", "A serial-destructive design conflicts with a repeated-plant sampling declaration.")
  }

  issue_df <- .agf_rbind_issues(issues)
  status <- if (any(issue_df$severity == "error")) "error" else if (any(issue_df$severity == "warning")) "warning" else "ok"
  out <- list(status = status, issues = issue_df, n_rows = nrow(data), n_times = if (!is.null(time)) length(unique(data[[time]][!is.na(data[[time]])])) else NA_integer_, sampling = sampling, design = design)
  class(out) <- "agri_growth_validation"

  if (strict && status == "error") {
    stop("Growth-data validation found error-level issues. Inspect `growth_validate(x)$issues`.", call. = FALSE)
  }
  out
}

#' @export
print.agri_growth_validation <- function(x, ...) {
  cat("<agri_growth_validation> status:", x$status, "\n")
  cat("Rows:", x$n_rows, " Distinct times:", x$n_times, " Sampling:", x$sampling, "\n")
  if (!nrow(x$issues)) {
    cat("No detectable issues. This is not a substitute for scientific review of the design.\n")
  } else {
    print(x$issues, row.names = FALSE)
  }
  invisible(x)
}

#' Build a design-aware analysis plan
#'
#' @param x An `agri_growth_data` or `agri_growth_design` object.
#' @param desirable_times Desirable number of time points per phase.
#' @return An `agri_growth_plan` object containing validation and recommendations.
#' @export

growth_plan <- function(x, desirable_times = 4L) {
  v <- growth_validate(x, strict = FALSE, desirable_times = desirable_times)
  if (inherits(x, "agri_growth_design")) {
    gd <- x$growth_data
    sampling <- x$sampling
    roles <- if (!is.null(gd)) gd$roles else x$roles
  } else {
    gd <- x
    sampling <- x$sampling
    roles <- x$roles
  }

  rec <- character()
  rec <- c(rec, "Inspect raw trajectories and the experimental-unit hierarchy before calculating rates.")
  if (sampling == "destructive") {
    rec <- c(rec, "For destructive harvests, summarize sampled plants or quadrats within the stable experimental unit and harvest date before forming intervals.")
  }
  if (sampling == "repeated") {
    rec <- c(rec, "Preserve plant-level trajectories; do not replace repeated plant measurements by independent time-specific means before deciding on the model.")
  }
  if (sampling == "auto") {
    rec <- c(rec, "Declare the sampling mechanism explicitly before inferential analysis.")
  }
  if (!is.null(roles$total_mass)) rec <- c(rec, "AGR and RGR are available when consecutive time points have valid total mass.")
  if (!is.null(roles$total_mass) && !is.null(roles$leaf_area)) rec <- c(rec, "NAR can be calculated for intervals with positive leaf area and total mass.")
  if (!is.null(roles$leaf_area) && !is.null(roles$leaf_mass)) rec <- c(rec, "SLA is available and can be combined with LMR to verify LAR = SLA x LMR.")
  if (!is.null(roles$ground_area) && !is.null(roles$leaf_area)) rec <- c(rec, "LAI and trapezoidal LAD can be calculated on a ground-area basis.")
  if (!is.null(roles$ground_area) && !is.null(roles$total_mass)) rec <- c(rec, "CGR can be calculated when total biomass refers to the declared ground area.")
  component_roles <- c(roles$root_mass, roles$stem_mass, roles$leaf_mass, roles$reproductive_mass)
  component_roles <- component_roles[!vapply(component_roles, is.null, logical(1))]
  if (length(component_roles) >= 2L) rec <- c(rec, "Biomass partitioning can be summarized; inspect unallocated biomass before normalizing fractions.")
  if (v$n_times < desirable_times) rec <- c(rec, "Trajectory-shape inference is weak with few harvest dates. Consider additional harvest times in future experiments.")

  out <- list(validation = v, recommendations = unique(rec))
  class(out) <- "agri_growth_plan"
  out
}

#' @export
print.agri_growth_plan <- function(x, ...) {
  cat("<agri_growth_plan>\n")
  cat("Validation status:", x$validation$status, "\n\n")
  cat("Recommendations:\n")
  for (i in seq_along(x$recommendations)) cat(sprintf("%d. %s\n", i, x$recommendations[[i]]))
  invisible(x)
}
