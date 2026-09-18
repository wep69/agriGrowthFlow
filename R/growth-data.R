#' Declare a plant growth dataset
#'
#' @description
#' `growth_data()` records which columns play biological and experimental roles.
#' It does not alter the supplied observations. The explicit role map is used by
#' validation, visualization and classical growth-index functions.
#'
#' @param data A data frame.
#' @param time Name of the time column.
#' @param sampling Sampling structure: `"auto"`, `"repeated"`, `"destructive"`, or `"mixed"`.
#' @param experimental_unit Stable experimental-unit identifier, when available.
#' @param plant Optional plant identifier.
#' @param plot Optional plot identifier.
#' @param block Optional block identifier.
#' @param treatment Optional treatment identifier.
#' @param total_mass Optional total dry-mass column.
#' @param leaf_area Optional leaf-area column.
#' @param leaf_mass Optional leaf dry-mass column.
#' @param root_mass Optional root dry-mass column.
#' @param stem_mass Optional stem dry-mass column.
#' @param reproductive_mass Optional reproductive dry-mass column.
#' @param ground_area Optional ground-area column used for LAI and CGR.
#' @param units Named list describing physical units.
#' @param metadata Named list of contextual metadata.
#'
#' @return An object of class `agri_growth_data`.
#' @export
#'
#' @examples
#' # 1) Full declaration of a destructive-harvest trial
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(
#'   d, time = "day", sampling = "destructive",
#'   experimental_unit = "plot_id", treatment = "nitrogen", block = "block",
#'   total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
#'   leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2"
#' )
#' g
#'
#' # 2) Repeated measurements on the same plant
#' b <- growth_example_data("bean_repeated")
#' gb <- growth_data(
#'   b, time = "day", sampling = "repeated",
#'   experimental_unit = "plant_id", treatment = "water_regime",
#'   block = "block"
#' )
#' gb$sampling
#'
#' # 3) Minimal declaration and a missing-column error
#' g2 <- growth_data(d, time = "day", sampling = "destructive",
#'                   experimental_unit = "plot_id", total_mass = "total_mass_g")
#' g2$roles$time
#' try(growth_data(d, time = "dia", experimental_unit = "plot_id"))

growth_data <- function(data,
                        time,
                        sampling = c("auto", "repeated", "destructive", "mixed"),
                        experimental_unit = NULL,
                        plant = NULL,
                        plot = NULL,
                        block = NULL,
                        treatment = NULL,
                        total_mass = NULL,
                        leaf_area = NULL,
                        leaf_mass = NULL,
                        root_mass = NULL,
                        stem_mass = NULL,
                        reproductive_mass = NULL,
                        ground_area = NULL,
                        units = list(),
                        metadata = list()) {
  .agf_assert_data_frame(data)
  sampling <- .agf_match_sampling(sampling)

  role_args <- list(
    time = time,
    experimental_unit = experimental_unit,
    plant = plant,
    plot = plot,
    block = block,
    treatment = treatment,
    total_mass = total_mass,
    leaf_area = leaf_area,
    leaf_mass = leaf_mass,
    root_mass = root_mass,
    stem_mass = stem_mass,
    reproductive_mass = reproductive_mass,
    ground_area = ground_area
  )

  for (nm in names(role_args)) {
    .agf_assert_column(data, role_args[[nm]], arg = nm, allow_null = nm != "time")
  }

  if (!is.list(units)) stop("`units` must be a named list.", call. = FALSE)
  if (!is.list(metadata)) stop("`metadata` must be a named list.", call. = FALSE)

  out <- list(
    data = data,
    roles = role_args,
    sampling = sampling,
    units = units,
    metadata = metadata,
    created_with = "agriGrowthFlow"
  )
  class(out) <- "agri_growth_data"
  out
}

#' @export
#' @examples
#' # 1) Recover the original data frame
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", total_mass = "total_mass_g")
#' z <- as.data.frame(g)
#' class(z)
#'
#' # 2) Dimensions and names preserved
#' dim(z)
#' names(z)[1:4]
#'
#' # 3) Use the frame with ordinary functions
#' head(z, 3)
as.data.frame.agri_growth_data <- function(x, ...) {
  x$data
}

#' @export
#' @examples
#' # 1) Readable summary of the object
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", total_mass = "total_mass_g")
#' print(g)
#'
#' # 2) The return is the object itself, invisibly
#' x <- print(g)
#' identical(x, g)
#'
#' # 3) Internal structure
#' str(g, max.level = 1)
print.agri_growth_data <- function(x, ...) {
  cat("<agri_growth_data>\n")
  cat("Rows:", nrow(x$data), " Columns:", ncol(x$data), "\n")
  cat("Sampling:", x$sampling, "\n")
  cat("Time:", x$roles$time, "\n")
  if (!is.null(x$roles$experimental_unit)) cat("Experimental unit:", x$roles$experimental_unit, "\n")
  if (!is.null(x$roles$treatment)) cat("Treatment:", x$roles$treatment, "\n")
  observed_roles <- names(Filter(Negate(is.null), x$roles))
  cat("Declared roles:", paste(observed_roles, collapse = ", "), "\n")
  invisible(x)
}

#' Load a frozen teaching dataset
#'
#' @param name One of the frozen simulated teaching datasets documented in `growth_example_data()`, including the event and competition datasets added in version 0.5.0.
#' @return A data frame. All current teaching datasets are simulated and are not field evidence.
#' @export
#'
#' @examples
#' # 1) Dimensions of one teaching dataset
#' d <- growth_example_data("maize_destructive")
#' dim(d)
#'
#' # 2) Columns of another dataset
#' names(growth_example_data("coffee_diphasic"))
#'
#' # 3) Two more accepted names
#' growth_example_data("bean_repeated")
#' length(unique(growth_example_data("maize_density")$nitrogen))

growth_example_data <- function(name = c("maize_destructive", "bean_repeated", "soybean_partition", "sunflower_sigmoid", "wheat_expolinear", "soybean_irregular", "coffee_diphasic", "bean_defoliation", "maize_density", "tree_competition")) {
  name <- match.arg(name)
  file <- system.file("extdata", paste0(name, ".csv"), package = "agriGrowthFlow")
  if (!nzchar(file)) {
    stop("Teaching dataset was not found in the installed package: ", name, call. = FALSE)
  }
  utils::read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
}
