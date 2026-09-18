utils::globalVariables(c(".t", ".y", ".unit", ".group", ".block", "fit", "lower", "upper", "time", ".event_centered_time", ".post_event"))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

## Snapshot of the global random-number state. Call once, then register the
## returned closure with on.exit(restore(), add = TRUE) before a temporary
## set.seed(), so the caller's generator state is never modified.
## Resolve an `agri_growth_data` object into a plain data frame plus declared
## roles. Returns the input unchanged when it is already a data frame.
.agf_resolve_data <- function(x, time = NULL, response = NULL, unit = NULL,
                              total_mass = NULL, leaf_mass = NULL,
                              leaf_area = NULL) {
  if (!inherits(x, "agri_growth_data")) {
    return(list(data = x, time = time, response = response, unit = unit,
                total_mass = total_mass, leaf_mass = leaf_mass,
                leaf_area = leaf_area))
  }
  list(
    data = x$data,
    time = time %||% .agf_role(x, "time"),
    response = response %||% .agf_role(x, "total_mass") %||%
      .agf_role(x, "leaf_area") %||% .agf_role(x, "leaf_mass"),
    unit = unit %||% .agf_role(x, "experimental_unit") %||%
      .agf_role(x, "plant") %||% .agf_role(x, "plot"),
    total_mass = total_mass %||% .agf_role(x, "total_mass"),
    leaf_mass = leaf_mass %||% .agf_role(x, "leaf_mass"),
    leaf_area = leaf_area %||% .agf_role(x, "leaf_area")
  )
}

.agf_seed_snapshot <- function() {
  tinha <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  antes <- if (tinha) get(".Random.seed", envir = .GlobalEnv) else NULL
  function() {
    if (tinha) assign(".Random.seed", antes, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }
}

.agf_assert_data_frame <- function(data) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame or an object inheriting from data.frame.", call. = FALSE)
  }
  invisible(TRUE)
}

.agf_assert_column <- function(data, column, arg = deparse(substitute(column)), allow_null = TRUE) {
  if (is.null(column)) {
    if (allow_null) return(invisible(NULL))
    stop("`", arg, "` must identify a column in `data`.", call. = FALSE)
  }
  if (!is.character(column) || length(column) != 1L || is.na(column) || !nzchar(column)) {
    stop("`", arg, "` must be a single non-empty column name.", call. = FALSE)
  }
  if (!column %in% names(data)) {
    stop("Column `", column, "` supplied to `", arg, "` was not found in `data`.", call. = FALSE)
  }
  invisible(column)
}

.agf_assert_columns <- function(data, columns, arg = deparse(substitute(columns))) {
  if (is.null(columns)) return(invisible(NULL))
  if (!is.character(columns) || anyNA(columns) || any(!nzchar(columns))) {
    stop("`", arg, "` must contain valid column names.", call. = FALSE)
  }
  missing <- setdiff(columns, names(data))
  if (length(missing)) {
    stop("Columns not found for `", arg, "`: ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  invisible(columns)
}

.agf_assert_numeric <- function(x, name, positive = FALSE, nonnegative = FALSE) {
  if (!is.numeric(x)) stop("`", name, "` must be numeric.", call. = FALSE)
  if (positive && any(x <= 0, na.rm = TRUE)) {
    stop("`", name, "` must contain positive values where it is observed.", call. = FALSE)
  }
  if (nonnegative && any(x < 0, na.rm = TRUE)) {
    stop("`", name, "` must contain non-negative values where it is observed.", call. = FALSE)
  }
  invisible(TRUE)
}

.agf_match_sampling <- function(sampling) {
  match.arg(sampling, c("auto", "repeated", "destructive", "mixed"))
}

.agf_role <- function(x, role) {
  if (!inherits(x, "agri_growth_data")) return(NULL)
  x$roles[[role]] %||% NULL
}

.agf_unique_non_null <- function(x) {
  keep <- !vapply(x, is.null, logical(1))
  unique(unlist(x[keep], use.names = FALSE))
}

.agf_fmt <- function(x, digits = 4L) {
  format(signif(x, digits), trim = TRUE, scientific = FALSE)
}

.agf_group_key <- function(data, columns) {
  if (!length(columns)) return(rep(".all", nrow(data)))
  do.call(interaction, c(data[columns], list(drop = TRUE, lex.order = TRUE, sep = "\r")))
}

.agf_issue <- function(severity, code, message) {
  data.frame(
    severity = severity,
    code = code,
    message = message,
    stringsAsFactors = FALSE
  )
}

.agf_rbind_issues <- function(issues) {
  if (!length(issues)) {
    return(data.frame(
      severity = character(),
      code = character(),
      message = character(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, issues)
}

.agf_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("`growth_plot()` requires the ggplot2 package.", call. = FALSE)
  }
}

.agf_recycle_numeric <- function(values, names) {
  lens <- vapply(values, length, integer(1))
  if (any(lens == 0L)) stop("Numeric inputs must not be empty.", call. = FALSE)
  n <- max(lens)
  bad <- lens != 1L & lens != n
  if (any(bad)) {
    stop("Ambiguous vector recycling is not allowed. Input lengths must be 1 or the common maximum length. Problem inputs: ",
         paste(names[bad], collapse = ", "), ".", call. = FALSE)
  }
  out <- lapply(values, function(z) if (length(z) == 1L && n > 1L) rep(z, n) else z)
  names(out) <- names
  out
}
