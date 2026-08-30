.agf_prepare_longitudinal <- function(x,
                                      time = NULL,
                                      response = NULL,
                                      unit = NULL,
                                      group = NULL,
                                      block = NULL,
                                      aggregate = c("auto", "none", "mean"),
                                      require_unit = TRUE,
                                      min_times = 3L,
                                      auto_group = FALSE,
                                      auto_block = FALSE) {
  aggregate <- match.arg(aggregate)
  source_is_growth <- inherits(x, "agri_growth_data")
  sampling <- "unspecified"

  if (source_is_growth) {
    v <- growth_validate(x, strict = FALSE)
    if (identical(v$status, "error")) {
      stop("The declared growth-data structure contains error-level validation issues. Resolve them before longitudinal analysis.", call. = FALSE)
    }
    data <- x$data
    time <- time %||% .agf_role(x, "time")
    response <- response %||% .agf_role(x, "total_mass") %||% .agf_role(x, "leaf_area") %||% .agf_role(x, "leaf_mass")
    unit <- unit %||% .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot") %||% .agf_role(x, "plant")
    if (isTRUE(auto_group)) group <- group %||% .agf_role(x, "treatment")
    if (isTRUE(auto_block)) block <- block %||% .agf_role(x, "block")
    sampling <- x$sampling
  } else {
    .agf_assert_data_frame(x)
    data <- x
  }

  if (is.null(time) || is.null(response)) {
    stop("`time` and `response` must be supplied or declared in `growth_data()`.", call. = FALSE)
  }
  if (require_unit && is.null(unit)) {
    stop("A persistent `unit` is required for longitudinal or functional analysis.", call. = FALSE)
  }

  .agf_assert_column(data, time, "time", allow_null = FALSE)
  .agf_assert_column(data, response, "response", allow_null = FALSE)
  .agf_assert_column(data, unit, "unit", allow_null = !require_unit)
  .agf_assert_column(data, group, "group", allow_null = TRUE)
  .agf_assert_column(data, block, "block", allow_null = TRUE)
  if (!is.numeric(data[[response]])) stop("The response must be numeric.", call. = FALSE)

  keep_cols <- unique(c(time, response, unit, group, block))
  keep_cols <- keep_cols[!is.na(keep_cols) & nzchar(keep_cols)]
  d <- data[keep_cols]
  complete_names <- c(time, response, unit, group, block)
  complete_names <- complete_names[!is.na(complete_names) & nzchar(complete_names)]
  d <- d[stats::complete.cases(d[complete_names]), , drop = FALSE]
  if (!nrow(d)) stop("No complete observations remain after role filtering.", call. = FALSE)

  d$.t <- .agf_numeric_time(d[[time]])
  d$.y <- as.numeric(d[[response]])
  d$.unit <- if (is.null(unit)) factor(".all") else factor(as.character(d[[unit]]))
  d$.group <- if (is.null(group)) factor(".all") else factor(as.character(d[[group]]))
  d$.block <- if (is.null(block)) factor(".all") else factor(as.character(d[[block]]))

  has_duplicate_unit_time <- !is.null(unit) && anyDuplicated(paste(d$.unit, d$.t)) > 0L
  do_aggregate <- identical(aggregate, "mean") ||
    (identical(aggregate, "auto") && !is.null(unit) && (identical(sampling, "destructive") || has_duplicate_unit_time))
  aggregation_note <- "none"
  if (do_aggregate) {
    before <- nrow(d)
    keys <- c(".unit", ".group", ".block", ".t")
    d <- stats::aggregate(d[".y"], by = d[keys], FUN = mean, na.rm = TRUE)
    d$.unit <- factor(d$.unit)
    d$.group <- factor(d$.group)
    d$.block <- factor(d$.block)
    aggregation_note <- paste0("mean within persistent unit x group x block x time: ", before, " -> ", nrow(d), " rows")
  }
  d <- d[order(d$.group, d$.block, d$.unit, d$.t), , drop = FALSE]

  if (length(unique(d$.t)) < as.integer(min_times)) {
    stop("At least ", min_times, " distinct time points are required for this analysis.", call. = FALSE)
  }
  if (require_unit && length(unique(d$.unit)) < 2L) {
    stop("At least two persistent units are required for longitudinal or functional analysis.", call. = FALSE)
  }

  attr(d, "time_name") <- time
  attr(d, "response_name") <- response
  attr(d, "unit_name") <- unit
  attr(d, "group_name") <- group
  attr(d, "block_name") <- block
  attr(d, "sampling") <- sampling
  attr(d, "aggregation") <- aggregation_note
  d
}

.agf_population_curve_data <- function(d) {
  # Equalize the contribution of persistent units before forming a population
  # trajectory. Technical replicates or duplicate rows at a unit-time point are
  # first reduced within that unit, regardless of sampling label.
  unit_time <- stats::aggregate(
    d[".y"],
    by = d[c(".unit", ".group", ".t")],
    FUN = mean,
    na.rm = TRUE
  )
  spl <- split(unit_time, interaction(unit_time$.group, unit_time$.t, drop = TRUE, lex.order = TRUE))
  rows <- lapply(spl, function(z) {
    n <- length(unique(z$.unit))
    sdz <- if (n > 1L) stats::sd(z$.y, na.rm = TRUE) else NA_real_
    data.frame(
      .group = as.character(z$.group[[1L]]),
      .t = z$.t[[1L]],
      .y = mean(z$.y, na.rm = TRUE),
      n_units = n,
      sd = sdz,
      se = if (n > 1L) sdz / sqrt(n) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$.group <- factor(out$.group, levels = levels(d$.group))
  out <- out[order(out$.group, out$.t), , drop = FALSE]
  rownames(out) <- NULL
  out
}
