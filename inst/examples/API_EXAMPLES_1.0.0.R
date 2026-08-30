# agriGrowthFlow 1.0.0 consolidated public API examples
# All bundled datasets are simulated teaching data.

maize <- growth_example_data("maize_destructive")
bean <- growth_example_data("bean_repeated")
soy <- growth_example_data("soybean_partition")
sun <- growth_example_data("sunflower_sigmoid")
wheat <- growth_example_data("wheat_expolinear")
soy_irregular <- growth_example_data("soybean_irregular")
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

# growth_example_data: representative patterns across all layers
growth_example_data("maize_destructive")
growth_example_data("sunflower_sigmoid")
growth_example_data("soybean_irregular")

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

# -----------------------------------------------------------------------------
# Version 0.3.0: longitudinal, flexible, functional, and multivariate growth API
# -----------------------------------------------------------------------------

# growth_mixed: three patterns
if (requireNamespace("nlme", quietly = TRUE)) {
  mix_height <- growth_mixed(bean, time = "day", response = "height_cm", unit = "plant_id",
                             group = "water_regime", block = "block", degree = 2, random_degree = 1)
  mix_area <- growth_mixed(bean, time = "day", response = "projected_leaf_area_m2", unit = "plant_id",
                           group = "water_regime", correlation = "car1", degree = 2)
  mix_spad <- growth_mixed(bean, time = "day", response = "spad", unit = "plant_id",
                           group = "water_regime", variance = "group", degree = 1, random_degree = 0)
}

# growth_mixed_diagnose: three patterns
if (requireNamespace("nlme", quietly = TRUE)) {
  growth_mixed_diagnose(mix_height)
  growth_mixed_diagnose(mix_area)
  growth_mixed_diagnose(mix_spad)
}

# growth_smooth: three patterns
smooth_height <- growth_smooth(bean, time = "day", response = "height_cm", unit = "plant_id",
                               group = "water_regime", method = "smooth_spline")
smooth_area <- growth_smooth(bean, time = "day", response = "projected_leaf_area_m2", unit = "plant_id",
                             group = "water_regime", method = "loess", span = 0.75)
smooth_irregular <- growth_smooth(soy_irregular, time = "day", response = "height_cm", unit = "plant_id",
                                  group = "water_regime", method = "smooth_spline")

# growth_smooth_predict: three patterns
growth_smooth_predict(smooth_height, n = 60)
growth_smooth_predict(smooth_area, time = seq(0, 60, by = 5))
growth_smooth_predict(smooth_irregular, n = 80)

# growth_derivative: three patterns
growth_derivative(smooth_height, order = 1, n = 60)
growth_derivative(smooth_height, order = 2, n = 60)
growth_derivative(smooth_area, order = 1, time = seq(7, 56, by = 7))

# growth_acceleration: three patterns
growth_acceleration(smooth_height, n = 60)
growth_acceleration(smooth_area, n = 60)
growth_acceleration(smooth_irregular, time = seq(7, 63, by = 7))

# growth_smooth_traits: three patterns
growth_smooth_traits(smooth_height, n = 300)
growth_smooth_traits(smooth_area, n = 300)
growth_smooth_traits(smooth_irregular, n = 300)

# growth_fpca: three patterns
fp_height <- growth_fpca(bean, time = "day", response = "height_cm", unit = "plant_id",
                         group = "water_regime", engine = "grid", npc = 2)
growth_fpca(bean, time = "day", response = "projected_leaf_area_m2", unit = "plant_id",
            group = "water_regime", engine = "grid", pve = 0.95)
growth_fpca(soy_irregular, time = "day", response = "height_cm", unit = "plant_id",
            group = "water_regime", engine = "grid", npc = 2, smooth = "linear")

# growth_functional: three patterns
growth_functional(bean, time = "day", response = "height_cm", unit = "plant_id", npc = 2)
growth_functional(bean, time = "day", response = "spad", unit = "plant_id", pve = 0.90)
growth_functional(soy_irregular, time = "day", response = "projected_canopy_area_m2",
                  unit = "plant_id", group = "water_regime", npc = 2)

# growth_curve_coefficients: three patterns
coef_mass <- growth_curve_coefficients(maize, time = "day", response = "total_mass_g",
                                       unit = "plot_id", group = "nitrogen", degree = 2)
growth_curve_coefficients(maize, time = "day", response = "leaf_area_m2",
                          unit = "plot_id", group = "nitrogen", degree = 2)
growth_curve_coefficients(bean, time = "day", response = "height_cm",
                          unit = "plant_id", group = "water_regime", degree = 2)

# growth_manova: three patterns
growth_manova(maize, time = "day", response = "total_mass_g",
              unit = "plot_id", group = "nitrogen", degree = 2, test = "Pillai")
growth_manova(maize, time = "day", response = "leaf_area_m2",
              unit = "plot_id", group = "nitrogen", degree = 2, test = "Wilks")
growth_manova(bean, time = "day", response = "height_cm",
              unit = "plant_id", group = "water_regime", degree = 2, test = "Pillai")



# -----------------------------------------------------------------------------
# Version 0.4.0: uncertainty, bootstrap, and Bayesian workflows
# -----------------------------------------------------------------------------

sun_u <- subset(growth_example_data("sunflower_sigmoid"), cultivar == unique(growth_example_data("sunflower_sigmoid")$cultivar)[1])
fit_u <- growth_fit(sun_u, "logistic", time = "day", response = "biomass_g", engine = "nls")

# growth_boot
b1 <- growth_boot(fit_u, R = 20, method = "case", seed = 1, engine = "nls")
b2 <- growth_boot(fit_u, R = 20, method = "residual", seed = 2, engine = "nls")
b3 <- growth_boot(fit_u, R = 20, method = "parametric", seed = 3, engine = "nls")

# growth_boot_ci
growth_boot_ci(b1, source = "coefficients")
growth_boot_ci(b1, source = "coefficients", parm = "mid", type = "basic")
growth_boot_ci(b2, source = "traits", parm = "t50", type = "percentile")

# growth_boot_traits
growth_boot_traits(b1)
growth_boot_traits(b1, traits = "t50")
growth_boot_traits(b2, traits = c("t50", "t90", "maximum_absolute_rate"))

# growth_selection_stability
growth_selection_stability(sun_u, c("logistic", "gompertz"), time = "day", response = "biomass_g", R = 20, seed = 1, engine = "nls")
growth_selection_stability(sun_u, c("logistic", "richards"), time = "day", response = "biomass_g", R = 20, seed = 2, engine = "nls")
growth_selection_stability(sun_u, c("logistic", "gompertz", "richards"), time = "day", response = "biomass_g", R = 20, seed = 3, engine = "nls")

# growth_prior
growth_prior(sun_u, "logistic", time = "day", response = "biomass_g")
growth_prior(sun_u, "gompertz", time = "day", response = "biomass_g")
growth_prior(sun_u, "richards", time = "day", response = "biomass_g")

# The following Bayesian examples are intentionally guarded because they compile Stan.
if (FALSE) {
  bb1 <- growth_bayes(sun_u, "logistic", time = "day", response = "biomass_g", chains = 4, iter = 2000, warmup = 1000, seed = 1)
  bb2 <- growth_bayes(sun_u, "gompertz", time = "day", response = "biomass_g", chains = 4, iter = 2000, warmup = 1000, seed = 2)
  bb3 <- growth_bayes(sun_u, "richards", time = "day", response = "biomass_g", chains = 4, iter = 2000, warmup = 1000, seed = 3)

  pp1 <- growth_prior_predict(sun_u, "logistic", time = "day", response = "biomass_g", chains = 4, iter = 1000, warmup = 500, seed = 1)
  pp2 <- growth_prior_predict(sun_u, "gompertz", time = "day", response = "biomass_g", chains = 4, iter = 1000, warmup = 500, seed = 2)
  pp3 <- growth_prior_predict(sun_u, "richards", time = "day", response = "biomass_g", chains = 4, iter = 1000, warmup = 500, seed = 3)

  growth_pp_check(bb1, type = "dens_overlay", ndraws = 50)
  growth_pp_check(bb2, type = "dens_overlay", ndraws = 50)
  growth_pp_check(bb3, type = "dens_overlay", ndraws = 50)

  growth_bayes_diagnose(bb1)
  growth_bayes_diagnose(bb2)
  growth_bayes_diagnose(bb3)

  growth_posterior_traits(bb1, ndraws = 500, seed = 1)
  growth_posterior_traits(bb2, ndraws = 500, seed = 2)
  growth_posterior_traits(bb3, ndraws = 500, seed = 3)

  growth_loo(bb1)
  growth_loo(bb2)
  growth_loo(bb3)

  growth_model_average(bb1, bb2, method = "stacking", type = "weights")
  growth_model_average(bb1, bb2, method = "pseudobma", BB = TRUE, type = "weights")
  growth_model_average(bb1, bb2, bb3, method = "stacking", type = "epred", ndraws = 500, seed = 1)
}

# ---- 0.5.0 Biological Events and Agronomic Decisions ----
coffee <- growth_example_data("coffee_diphasic")
coffee_c <- subset(coffee, treatment == "control")
bean_def <- growth_example_data("bean_defoliation")
density_dat <- growth_example_data("maize_density")
tree_dat <- growth_example_data("tree_competition")

if (FALSE) {
  growth_multiphase(coffee_c, time="day", response="biomass_g", n_phases=2, n_start=5, seed=1)
  growth_multiphase(coffee_c, time="day", response="biomass_g", n_phases=1, n_start=3, seed=2)
  growth_multiphase(coffee, time="day", response="biomass_g", n_phases=2, group="treatment", n_start=3, seed=3)

  growth_diphasic(coffee_c, time="day", response="biomass_g", n_start=5, seed=4)
  growth_diphasic(coffee, time="day", response="biomass_g", group="treatment", n_start=3, seed=5)
  growth_diphasic(subset(coffee,treatment=="stress"), time="day", response="biomass_g", n_start=5, seed=6)

  mp <- growth_diphasic(coffee_c, time="day", response="biomass_g", n_start=5, seed=7)
  growth_stability(mp)
  growth_stability(mp, n=1001)
  growth_stability(mp, interval=c(0,144), n=2001)
}

growth_changepoint(coffee_c, time="day", response="biomass_g")
growth_changepoint(coffee_c, time="day", response="biomass_g", min_segment=3)
growth_changepoint(subset(coffee,treatment=="stress"), time="day", response="biomass_g")

growth_event(bean_def, time="day", response="total_mass_g", event_time=21, unit="plant_id", event_type="defoliation")
growth_event(bean_def, time="day", response="leaf_area_m2", event_time=35, unit="plant_id")
growth_event(subset(bean_def,treatment=="defoliated"), time="day", response="total_mass_g", event_time=21, event_amount=1)

if (FALSE) {
  growth_defoliation(subset(bean_def, plant_id==unique(bean_def$plant_id)[1]), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", total_loss="total_loss_g", leaf_mass_loss="leaf_mass_loss_g", leaf_area_loss="leaf_area_loss_m2")
  growth_defoliation(subset(bean_def,treatment=="defoliated"), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", total_loss="total_loss_g", leaf_mass_loss="leaf_mass_loss_g", leaf_area_loss="leaf_area_loss_m2", unit="plant_id")
  growth_defoliation(subset(bean_def,treatment=="control"), time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2", unit="plant_id", step=.5)
}

growth_compensation(bean_def, group="treatment", control="control", response="total_mass_g", time="day", unit="plant_id", metric="final")
growth_compensation(bean_def, group="treatment", control="control", response="total_mass_g", time="day", unit="plant_id", metric="auc")
growth_compensation(bean_def, group="treatment", control="control", response="leaf_area_m2", time="day", unit="plant_id", metric="slope")

growth_density(density_dat, density="density_plants_m2", plant_mass="plant_mass_g")
growth_density(subset(density_dat,nitrogen=="low"), density="density_plants_m2", plant_mass="plant_mass_g")
growth_density(subset(density_dat,nitrogen=="high"), density="density_plants_m2", plant_mass="plant_mass_g")

growth_neighbor(tree_dat, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=3)
growth_neighbor(tree_dat, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=5, distance_power=2)
growth_neighbor(tree_dat, id="plant_id", x="x_m", y="y_m", size="size_cm", radius=4, size_power=0)

growth_competition(c(1,1), times=0:5, r=.4, K=20, competition_matrix=matrix(c(0,.2,.2,0),2), dt=.1)
growth_competition(c(1,2,1), times=0:4, r=c(.3,.4,.35), K=25, competition_matrix=matrix(0,3,3))
growth_competition(c(2,2), times=c(0,1,2), r=.5, K=c(15,20), competition_matrix=matrix(c(0,.5,.1,0),2), dt=.05)

if (FALSE) {
  sf <- growth_fit(subset(growth_example_data("sunflower_sigmoid"), cultivar=="C1"), "logistic", time="day", response="biomass_g")
  growth_threshold(sf,.5,type="fraction")
  growth_threshold(sf,100,type="absolute")
  growth_threshold(sf,.9,type="fraction",direction="increasing")

  growth_plateau_time(sf,criterion="response")
  growth_plateau_time(sf,criterion="rate")
  growth_plateau_time(sf,criterion="response",response_fraction=.9)

  growth_harvest_opt(sf,price=1,cost_per_time=.2)
  growth_harvest_opt(sf,price=1,discount_rate=.01)
  growth_harvest_opt(sf,price=2,cost_per_time=.1,harvest_cost=3)

  growth_schedule(sf,n=6)
  growth_schedule(sf,n=8,method="rate_curvature")
  growth_schedule(time_range=c(0,100),n=6,method="equal")
}

growth_design_sim("logistic",c(asym=100,mid=30,scale=8),times=seq(0,60,10),n_unit=6,sigma=3,seed=1)
growth_design_sim("gompertz",c(asym=80,mid=25,scale=7),times=0:5*10,n_unit=4,sigma=2,random_asym_sd=.1,seed=2)
growth_design_sim("logistic",c(asym=100,mid=30,scale=8),times=seq(0,60,10),n_unit=8,sigma=3,treatment=rep(c("C","T"),each=4),treatment_multiplier=c(C=1,T=1.15),seed=3)

growth_power(effect=5,trait_sd=8,n_unit=20,n_sim=500,seed=1)
growth_power(effect=5,trait_sd=8,n_unit=40,n_sim=500,seed=1)
growth_power(effect=8,trait_sd=8,n_unit=20,n_sim=500,alternative="greater",seed=2)

# -----------------------------------------------------------------------------
# 1.0.0 consolidated release API
# -----------------------------------------------------------------------------

# growth_method_guide(): three design/objective patterns
agf_mg1 <- growth_method_guide(gm, objective = "rates")
agf_mg2 <- growth_method_guide(gm, objective = "trajectory")
agf_mg3 <- growth_method_guide(bean, time = "day", response = "height_cm", unit = "plant_id", group = "water_regime", objective = "treatment_comparison")

# growth_workflow(): planning, explicit parametric, explicit smooth
agf_w1 <- growth_workflow(gm, objective = "trajectory", execute = FALSE, seed = 101)
agf_w2 <- growth_workflow(sun, time = "day", response = "biomass_g", strategy = "parametric", models = c("logistic", "gompertz"), n_start = 3, seed = 102)
agf_w3 <- growth_workflow(bean, time = "day", response = "height_cm", unit = "plant_id", group = "water_regime", strategy = "smooth", smooth_method = "smooth_spline", seed = 103)

# growth_workflow_audit(): audits from different workflow types
growth_workflow_audit(agf_w1)
growth_workflow_audit(agf_w2)
growth_workflow_audit(agf_w3)

# growth_table(): audit, traits, direct fit coefficients
growth_table(agf_w1, component = "audit")
growth_table(agf_w2, component = "traits")
growth_table(fit_log, component = "coefficients")

# growth_report(): return text and optionally write Markdown
growth_report(agf_w1)
growth_report(agf_w2, title = "Parametric growth analysis")
growth_report(agf_w1, file = tempfile(fileext = ".md"))

# growth_export(): RDS, CSV and bundle
invisible(growth_export(agf_w1, tempfile(fileext = ".rds"), format = "rds"))
invisible(growth_export(growth_workflow_audit(agf_w1), tempfile(fileext = ".csv"), format = "csv"))
invisible(growth_export(agf_w1, tempfile(pattern = "agf_bundle_"), format = "bundle"))
