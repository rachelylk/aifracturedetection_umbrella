# analysis/R/3_models_subgroups_RVE.R
# Subgroup analyses + multivariable mixed models + RVE (CR2)

source("analysis/R/0_setup.R")

dat_list <- readRDS(file.path(paths$out_models, "prepared_data.rds"))

dat_se_ai <- dat_list$dat_se_ai
dat_sp_ai <- dat_list$dat_sp_ai

# -------------------------------------------------------------------
# Recode factors and set "mixed" as reference where relevant
# -------------------------------------------------------------------

dat_se_ai <- dat_se_ai %>%
  mutate(
    modality   = factor(modality),
    anatomy    = factor(anatomy),
    validation = factor(validation),
    population = factor(population),
    modality   = relevel(modality,   ref = "mixed"),
    anatomy    = relevel(anatomy,    ref = "mixed"),
    validation = relevel(validation, ref = "mixed"),
    population = relevel(population, ref = "mixed")
  )

dat_sp_ai <- dat_sp_ai %>%
  mutate(
    modality   = factor(modality),
    anatomy    = factor(anatomy),
    validation = factor(validation),
    population = factor(population),
    modality   = relevel(modality,   ref = "mixed"),
    anatomy    = relevel(anatomy,    ref = "mixed"),
    validation = relevel(validation, ref = "mixed"),
    population = relevel(population, ref = "mixed")
  )

# -------------------------------------------------------------------
# Helper for simple subgroup model
# -------------------------------------------------------------------

fit_subgroup <- function(dat, filter_expr, label) {
  sub <- dat %>% dplyr::filter({{ filter_expr }}) %>% droplevels()
  if (nrow(sub) == 0) return(NULL)
  m <- rma.mv(
    yi = yi,
    V  = vi,
    slab = meta_id,
    data = sub,
    random = ~ 1 | meta_id/row_id,
    test = "t",
    method = "REML"
  )
  pred <- predict(m, transf = plogis)
  tibble::tibble(
    subgroup = label,
    n_rows   = nrow(sub),
    est      = pred$pred,
    ci_lb    = pred$ci.lb,
    ci_ub    = pred$ci.ub
  )
}

# -------------------------------------------------------------------
# 2: Individual subgroup analyses (AI alone)
# -------------------------------------------------------------------

subgroups_sens <- dplyr::bind_rows(
  # MODALITY
  fit_subgroup(dat_se_ai, modality == "radiographs", "sens_modality_radiographs"),
  fit_subgroup(dat_se_ai, modality == "ct",          "sens_modality_ct"),
  
  # ANATOMY
  fit_subgroup(dat_se_ai, anatomy == "axial",       "sens_anatomy_axial"),
  fit_subgroup(dat_se_ai, anatomy == "lower limb",  "sens_anatomy_lower_limb"),
  fit_subgroup(dat_se_ai, anatomy == "upper limb",  "sens_anatomy_upper_limb"),
  fit_subgroup(dat_se_ai, anatomy == "skull",       "sens_anatomy_skull"),
  
  # VALIDATION
  fit_subgroup(dat_se_ai, validation == "internal", "sens_validation_internal"),
  fit_subgroup(dat_se_ai, validation == "external", "sens_validation_external"),
  
  # POPULATION
  fit_subgroup(dat_se_ai, population == "adults",    "sens_population_adults"),
  fit_subgroup(dat_se_ai, population == "paediatric","sens_population_paediatric")
)

subgroups_spec <- dplyr::bind_rows(
  # MODALITY
  fit_subgroup(dat_sp_ai, modality == "radiographs", "spec_modality_radiographs"),
  fit_subgroup(dat_sp_ai, modality == "ct",          "spec_modality_ct"),
  
  # ANATOMY
  fit_subgroup(dat_sp_ai, anatomy == "axial",       "spec_anatomy_axial"),
  fit_subgroup(dat_sp_ai, anatomy == "lower limb",  "spec_anatomy_lower_limb"),
  fit_subgroup(dat_sp_ai, anatomy == "upper limb",  "spec_anatomy_upper_limb"),
  fit_subgroup(dat_sp_ai, anatomy == "skull",       "spec_anatomy_skull"),
  
  # VALIDATION
  fit_subgroup(dat_sp_ai, validation == "internal", "spec_validation_internal"),
  fit_subgroup(dat_sp_ai, validation == "external", "spec_validation_external"),
  
  # POPULATION
  fit_subgroup(dat_sp_ai, population == "adults",    "spec_population_adults"),
  fit_subgroup(dat_sp_ai, population == "paediatric","spec_population_paediatric")
)

readr::write_csv(
  subgroups_sens,
  file.path(paths$out_tables, "subgroups_ai_sensitivity.csv")
)

readr::write_csv(
  subgroups_spec,
  file.path(paths$out_tables, "subgroups_ai_specificity.csv")
)

# -------------------------------------------------------------------
# 3: Multivariable 3-level mixed-effects models with moderators
# -------------------------------------------------------------------

mod_se_model <- rma.mv(
  yi = yi, V = vi,
  slab   = meta_id,
  data   = dat_se_ai,
  random = ~ 1 | meta_id/row_id,
  test   = "t",
  method = "REML",
  mods   = ~ modality + anatomy + validation + population
)

mod_sp_model <- rma.mv(
  yi = yi, V = vi,
  slab   = meta_id,
  data   = dat_sp_ai,
  random = ~ 1 | meta_id/row_id,
  test   = "t",
  method = "REML",
  mods   = ~ modality + anatomy + validation + population
)

saveRDS(
  list(
    mod_se_model = mod_se_model,
    mod_sp_model = mod_sp_model
  ),
  file = file.path(paths$out_models, "multivariable_models.rds")
)

# -------------------------------------------------------------------
# 2b: RVE (CR2) estimates
# -------------------------------------------------------------------

rho <- 0.5

Vse <- with(
  dat_se_ai,
  wildmeta::impute_covariance_matrix(
    vi      = vi,
    cluster = meta_id,
    r       = rho
  )
)

cr2_se_model <- rma.mv(
  yi ~ 1 + modality + anatomy + validation + population,
  V      = Vse,
  random = ~ 1 | meta_id/row_id,
  data   = dat_se_ai,
  sparse = TRUE
)

Vsp <- with(
  dat_sp_ai,
  wildmeta::impute_covariance_matrix(
    vi      = vi,
    cluster = meta_id,
    r       = rho
  )
)

cr2_sp_model <- rma.mv(
  yi ~ 1 + modality + anatomy + validation + population,
  V      = Vsp,
  random = ~ 1 | meta_id/row_id,
  data   = dat_sp_ai,
  sparse = TRUE
)

cr2_sens <- clubSandwich::conf_int(cr2_se_model, vcov = "CR2") %>%
  as.data.frame() %>%
  tibble::rownames_to_column("term")

cr2_spec <- clubSandwich::conf_int(cr2_sp_model, vcov = "CR2") %>%
  as.data.frame() %>%
  tibble::rownames_to_column("term")

cr2_prob_sens <- cr2_sens %>%
  mutate(
    estimate_prob = plogis(beta),
    ci.lb_prob    = plogis(`CI_L`),
    ci.ub_prob    = plogis(`CI_U`)
  ) %>%
  dplyr::select(term, estimate_prob, ci.lb_prob, ci.ub_prob)

cr2_prob_spec <- cr2_spec %>%
  mutate(
    estimate_prob = plogis(beta),
    ci.lb_prob    = plogis(`CI_L`),
    ci.ub_prob    = plogis(`CI_U`)
  ) %>%
  dplyr::select(term, estimate_prob, ci.lb_prob, ci.ub_prob)

readr::write_csv(
  cr2_prob_sens,
  file.path(paths$out_tables, "cr2_prob_sensitivity.csv")
)

readr::write_csv(
  cr2_prob_spec,
  file.path(paths$out_tables, "cr2_prob_specificity.csv")
)

saveRDS(
  list(
    cr2_se_model   = cr2_se_model,
    cr2_sp_model   = cr2_sp_model,
    cr2_prob_sens  = cr2_prob_sens,
    cr2_prob_spec  = cr2_prob_spec
  ),
  file = file.path(paths$out_models, "rve_models.rds")
)

message("Subgroup, multivariable, and RVE models fitted and saved.")
