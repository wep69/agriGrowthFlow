#' Plot plant-growth trajectories
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param response Response column. For `agri_growth_data`, defaults to total mass,
#'   then leaf area, then leaf mass when available.
#' @param time Time column; inherited from `growth_data()` when omitted.
#' @param group Optional grouping/color column; treatment is the default when declared.
#' @param facet Optional facet column.
#' @param summary One of `"raw"`, `"mean_se"`, or `"both"`.
#' @param log_y Use a logarithmic y scale.
#' @param connect Logical or `NULL`. With `NULL` (default), raw observations are connected only for repeated non-destructive sampling. Destructive-harvest observations are never connected automatically because different harvested plants or quadrats are not longitudinal subjects.
#'
#' @return A ggplot object.
#' @export
#' @examples
#' # 1) Trajectories by treatment
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", treatment = "nitrogen",
#'                  total_mass = "total_mass_g")
#' growth_plot(g, response = "total_mass_g", group = "nitrogen")
#'
#' # 2) Mean with standard error on a log scale
#' growth_plot(g, response = "total_mass_g", group = "nitrogen",
#'             summary = "mean_se", log_y = TRUE)
#'
#' # 3) Faceted by block
#' growth_plot(g, response = "total_mass_g", group = "nitrogen", facet = "block")

growth_plot <- function(x,
                        response = NULL,
                        time = NULL,
                        group = NULL,
                        facet = NULL,
                        summary = c("raw", "mean_se", "both"),
                        log_y = FALSE,
                        connect = NULL) {
  .agf_require_ggplot2()
  summary <- match.arg(summary)
  sampling <- "unspecified"
  if (inherits(x, "agri_growth_data")) {
    data <- x$data
    sampling <- x$sampling
    time <- time %||% .agf_role(x, "time")
    response <- response %||% .agf_role(x, "total_mass") %||% .agf_role(x, "leaf_area") %||% .agf_role(x, "leaf_mass")
    group <- group %||% .agf_role(x, "treatment")
    unit <- .agf_role(x, "plant") %||% .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot")
  } else {
    .agf_assert_data_frame(x)
    data <- x
    unit <- NULL
  }
  .agf_assert_column(data, time, "time", allow_null = FALSE)
  .agf_assert_column(data, response, "response", allow_null = FALSE)
  .agf_assert_column(data, group, "group", allow_null = TRUE)
  .agf_assert_column(data, facet, "facet", allow_null = TRUE)
  if (is.null(connect)) {
    connect <- identical(sampling, "repeated")
  }
  if (!is.logical(connect) || length(connect) != 1L || is.na(connect)) {
    stop("`connect` must be TRUE, FALSE, or NULL.", call. = FALSE)
  }
  if (identical(sampling, "destructive") && isTRUE(connect)) {
    warning("Raw destructive-harvest observations represent different harvested plants or quadrats and will not be connected as individual trajectories. Use summarized curves or `growth_indices(x)$aggregated` for stable experimental-unit trajectories.", call. = FALSE)
    connect <- FALSE
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(x = !!rlang::sym(time), y = !!rlang::sym(response)))
  if (!is.null(group)) {
    p <- p + ggplot2::aes(colour = !!rlang::sym(group))
  }

  if (summary %in% c("raw", "both")) {
    p <- p + ggplot2::geom_point(alpha = if (summary == "both") 0.45 else 0.75)
    if (connect && !is.null(unit)) {
      if (is.null(group)) {
        p <- p + ggplot2::geom_line(ggplot2::aes(group = !!rlang::sym(unit)), alpha = 0.25)
      } else {
        p <- p + ggplot2::geom_line(ggplot2::aes(group = !!rlang::sym(unit)), alpha = 0.20)
      }
    }
  }
  if (summary %in% c("mean_se", "both")) {
    group_mapping <- if (is.null(group)) {
      ggplot2::aes(group = 1)
    } else {
      ggplot2::aes(group = !!rlang::sym(group))
    }
    p <- p + ggplot2::stat_summary(mapping = group_mapping, fun = mean, geom = "line", linewidth = 0.9)
    p <- p + ggplot2::stat_summary(mapping = group_mapping, fun.data = ggplot2::mean_se, geom = "errorbar", width = 0)
  }
  if (!is.null(facet)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet)))
  }
  p <- p + ggplot2::labs(x = time, y = response, colour = group) + ggplot2::theme_bw()
  if (log_y) p <- p + ggplot2::scale_y_log10()
  p
}
