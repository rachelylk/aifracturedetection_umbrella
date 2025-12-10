# analysis/R/6_check3Lmodelfit.R
# Appendix: check 3-level vs 2-level models (AI-alone)

source("analysis/R/0_setup.R")

# Load prepared data and main models
dat_list    <- readRDS(file.path(paths$out_models, "prepared_data.rds"))
main_models <- readRDS(file.path(paths$out_models, "main_models.rds"))

dat_se_ai <- dat_list$dat_se_ai
dat_sp_ai <- dat_list$dat_sp_ai

ai_3L_sensitivity <- main_models$ai_3L_sensitivity
ai_3L_specificity <- main_models$ai_3L_specificity

# -------------------------------------------------------------------
# Fit constrained models treating meta-analyses as 2-level
# sigma2 = c(0, NA) forces within-meta variance = 0
# -------------------------------------------------------------------

check_se_3L <- metafor::rma.mv(
  yi    = yi,
  V     = vi,
  slab  = meta_id,
  data  = dat_se_ai,
  random = ~ 1 | meta_id/row_id,
  test   = "t",
  method = "REML",
  sigma2 = c(0, NA)
)

check_sp_3L <- metafor::rma.mv(
  yi    = yi,
  V     = vi,
  slab  = meta_id,
  data  = dat_sp_ai,
  random = ~ 1 | meta_id/row_id,
  test   = "t",
  method = "REML",
  sigma2 = c(0, NA)
)

# Back-transform estimates + CIs to probability scale
check_se_3L_summary <- with(
  check_se_3L,
  c(
    estimate = plogis(b[1, 1]),
    ci_lb    = plogis(ci.lb),
    ci_ub    = plogis(ci.ub)
  )
)

check_sp_3L_summary <- with(
  check_sp_3L,
  c(
    estimate = plogis(b[1, 1]),
    ci_lb    = plogis(ci.lb),
    ci_ub    = plogis(ci.ub)
  )
)

# Likelihood ratio tests: 3-level vs constrained 2-level
anova_se <- anova(ai_3L_sensitivity, check_se_3L)
anova_sp <- anova(ai_3L_specificity, check_sp_3L)

# Collect into a small appendix table
appendix_table <- dplyr::bind_rows(
  tibble::tibble(
    metric   = "sensitivity",
    model    = c("3-level", "2-level"),
    est      = c(
      plogis(ai_3L_sensitivity$b[1, 1]),
      check_se_3L_summary["estimate"]
    ),
    ci_lb    = c(
      plogis(ai_3L_sensitivity$ci.lb),
      check_se_3L_summary["ci_lb"]
    ),
    ci_ub    = c(
      plogis(ai_3L_sensitivity$ci.ub),
      check_se_3L_summary["ci_ub"]
    ),
    LR_test_p = c(anova_se$"p-value"[2], NA_real_)
  ),
  tibble::tibble(
    metric   = "specificity",
    model    = c("3-level", "2-level"),
    est      = c(
      plogis(ai_3L_specificity$b[1, 1]),
      check_sp_3L_summary["estimate"]
    ),
    ci_lb    = c(
      plogis(ai_3L_specificity$ci.lb),
      check_sp_3L_summary["ci_lb"]
    ),
    ci_ub    = c(
      plogis(ai_3L_specificity$ci.ub),
      check_sp_3L_summary["ci_ub"]
    ),
    LR_test_p = c(anova_sp$"p-value"[2], NA_real_)
  )
)

# Save objects
saveRDS(
  list(
    check_se_3L = check_se_3L,
    check_sp_3L = check_sp_3L,
    anova_se    = anova_se,
    anova_sp    = anova_sp
  ),
  file = file.path(paths$out_models, "appendix_model_checks.rds")
)

readr::write_csv(
  appendix_table,
  file.path(paths$out_tables, "appendix_model_checks.csv")
)

message("Appendix 3L vs 2L model checks completed.")
