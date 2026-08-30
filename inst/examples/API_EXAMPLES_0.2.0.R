# agriGrowthFlow 0.2.0 public API examples
# All bundled datasets are simulated teaching data.

maize <- growth_example_data("maize_destructive")
bean <- growth_example_data("bean_repeated")
soy <- growth_example_data("soybean_partition")
sun <- growth_example_data("sunflower_sigmoid")
wheat <- growth_example_data("wheat_expolinear")
sun1 <- subset(sun, cultivar == unique(sun$cultivar)[1])
wheat1 <- subset(wheat, nitrogen == unique(wheat$nitrogen)[1])

gm <- growth_data(maize, time = "day", sampling = "destructive", experimental_unit = "plot_id",
                  treatment = "nitrogen", block = "block", total_mass = "total_mass_g",
                  leaf_area = "leaf_area_m2", leaf_mass = "leaf_mass_g", root_mass = "root_mass_g",
                  stem_mass = "stem_mass_g", reproductive_mass = "reproductive_mass_g",
                  ground_area = "ground_area_m2")
gb <- growth_data(bean, time = "day", sampling = "repeated", experimental_unit = "plant_id",
                  plant = "plant_id", treatment = "water_regime", block = "block",
                  leaf_area = "projected_leaf_area_m2")

# growth_example_data: three patterns
growth_example_data("maize_destructive")
growth_example_data("sunflower_sigmoid")
growth_example_data("wheat_expolinear")

# growth_data: three patterns
growth_data(maize, time = "day", sampling = "destructive", experimental_unit = "plot_id")
growth_data(bean, time = "day", sampling = "repeated", experimental_unit = "plant_id", plant = "plant_id")
growth_data(soy, time = "day", sampling = "destructive", experimental_unit = "plot_id", total_mass = "total_mass_g")

# growth_design: three patterns
growth_design(gm, design = "rcbd")
growth_design(gm, design = "serial_destructive")
growth_design(gb, design = "repeated")

# growth_validate: three patterns
growth_validate(gm)
growth_validate(gb)
growth_validate(growth_design(gm, design = "rcbd"))

# growth_plan: three patterns
growth_plan(gm)
growth_plan(gb)
growth_plan(growth_design(gm, design = "rcbd"))

# growth_plot: three patterns
growth_plot(gm, response = "total_mass_g", group = "nitrogen", summary = "raw")
growth_plot(gm, response = "total_mass_g", group = "nitrogen", summary = "both")
growth_plot(gb, response = "projected_leaf_area_m2", group = "water_regime", summary = "both")

# growth_agr: three patterns
growth_agr(10, 20, 0, 5)
growth_agr(c(10, 12), c(20, 21), 0, 5)
growth_agr(c(5, 8, 10), c(8, 12, 14), c(0, 5, 10), c(5, 10, 15))

# growth_rgr: three patterns
growth_rgr(10, 20, 0, 5)
growth_rgr(c(10, 12), c(20, 21), 0, 5)
growth_rgr(c(5, 8), c(8, 12), c(0, 5), c(5, 10))

# growth_nar: three patterns
growth_nar(10, 20, 0.05, 0.08, 0, 5)
growth_nar(10, 20, 0.05, 0.05, 0, 5)
growth_nar(c(10, 15), c(20, 24), c(0.05, 0.07), c(0.08, 0.09), 0, 5)

# growth_lar: three patterns
growth_lar(0.05, 10)
growth_lar(c(0.05, 0.08), c(10, 20))
growth_lar(c(0.05, 0.08), 10)

# growth_sla: three patterns
growth_sla(0.05, 2)
growth_sla(c(0.05, 0.08), c(2, 3))
growth_sla(c(0.05, 0.08), 2)

# growth_lmr: three patterns
growth_lmr(2, 10)
growth_lmr(c(2, 3), c(10, 15))
growth_lmr(c(2, 3), 10)

# growth_lai: three patterns
growth_lai(0.05, 0.1)
growth_lai(c(0.05, 0.08), c(0.1, 0.1))
growth_lai(c(0.05, 0.08), 0.1)

# growth_cgr: three patterns
growth_cgr(10, 20, 0, 5, ground_area = 0.5)
growth_cgr(c(10, 12), c(20, 22), 0, 5, ground_area = 0.5)
growth_cgr(c(10, 12), c(20, 22), c(0, 5), c(5, 10), ground_area = c(0.5, 0.5))

# growth_lad: three patterns
growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10))
growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10), intervals = TRUE)
growth_lad(c(0.5, NA, 1.2), c(0, 5, 10), na.rm = TRUE)

# growth_classical: three patterns
growth_classical(gm)
growth_classical(gm, by = c("nitrogen", "block"))
growth_classical(gm, unit = "plot_id")

# growth_indices: three patterns
growth_indices(gm)
growth_indices(gm, by = "nitrogen")
growth_indices(gm, unit = "plot_id")

# growth_partition: three patterns
growth_partition(gm)
growth_partition(soy, total_mass = "total_mass_g", components = c("leaf_mass_g", "root_mass_g", "stem_mass_g", "reproductive_mass_g"))
growth_partition(soy, components = c("leaf_mass_g", "root_mass_g", "stem_mass_g", "reproductive_mass_g"), normalize = TRUE)

# growth_allometry: three patterns
growth_allometry(soy, "root_mass_g", "total_mass_g")
growth_allometry(soy, "leaf_mass_g", "total_mass_g", group = "cultivar")
growth_allometry(soy, "stem_mass_g", "total_mass_g", level = 0.90)

# growth_models: three patterns
growth_models()
subset(growth_models(), finite_upper_level)
growth_models()[growth_models()$model == "expolinear", ]

# growth_start: three patterns
growth_start(sun1, "logistic", time = "day", response = "biomass_g")
growth_start(sun1, "gompertz", time = "day", response = "biomass_g")
growth_start(wheat1, "expolinear", time = "day", response = "biomass_g_m2")

# growth_fit: three patterns
fit_log <- growth_fit(sun1, "logistic", time = "day", response = "biomass_g", engine = "nls")
fit_set <- growth_fit(sun1, c("logistic", "gompertz"), time = "day", response = "biomass_g", engine = "nls")
fit_groups <- growth_fit(sun, "logistic", time = "day", response = "biomass_g", group = "cultivar", engine = "nls")

# growth_multistart: three patterns
growth_multistart(sun1, "logistic", time = "day", response = "biomass_g", n_start = 5, seed = 1, engine = "nls")
growth_multistart(sun1, "gompertz", time = "day", response = "biomass_g", n_start = 5, seed = 2, engine = "nls")
growth_multistart(wheat1, "expolinear", time = "day", response = "biomass_g_m2", n_start = 5, seed = 3, engine = "nls")

# growth_predict: three patterns
growth_predict(fit_log)
growth_predict(fit_log, time = seq(10, 70, by = 10), interval = "confidence")
growth_predict(fit_log, time = seq(10, 70, by = 10), interval = "prediction")

# growth_compare: three patterns
growth_compare(fit_set)
growth_compare(fit_set$fits$logistic, fit_set$fits$gompertz)
head(growth_compare(fit_set))

# growth_diagnose: three patterns
growth_diagnose(fit_log)
growth_diagnose(fit_log)$issues
growth_diagnose(fit_log)$attempts

# growth_traits: three patterns
growth_traits(fit_log)
growth_traits(fit_set)
growth_traits(fit_groups)

# growth_inflection: three patterns
growth_inflection(fit_log)
growth_inflection(fit_set)
growth_inflection(fit_groups)

# growth_maxrate: three patterns
growth_maxrate(fit_log)
growth_maxrate(fit_set)
growth_maxrate(fit_groups)

# growth_time_to: three patterns
growth_time_to(fit_log, fraction = c(0.1, 0.5, 0.9))
growth_time_to(fit_log, target = c(50, 100))
growth_time_to(fit_groups, fraction = 0.5)
