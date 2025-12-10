# analysis/R/2_models_main.R
# Main 3-level models: AI alone, clinicians, AI-assist

source("analysis/R/0_setup.R")

# -------------------------------------------------------------------
# Load prepared data
# -------------------------------------------------------------------
dat_list <- readRDS(file.path(paths$out_models, "prepared_data.rds"))

dat_se       <- dat_list$dat_se
dat_sp       <- dat_list$dat_sp
dat_se_ai    <- dat_list$dat_se_ai
dat_sp_ai    <- dat_list$dat_sp_ai
dat_se_clin  <- dat_list$dat_se_clin
dat_sp_clin  <- dat_list$dat_sp_clin
assist_se    <- dat_list$assist_se
assist_sp    <- dat_list$assist_sp

# Helper to fit 3L model and back-transform
fit_3L <- function(dat, label) {
  m <- rma.mv(
    yi = yi,
    V  = vi,
    slab = meta_id,
    data = dat,
    random = ~ 1 | meta_id/row_id,
    test = "t",
    method = "REML"
  )
  pred <- predict(m, transf = plogis)
  list(model = m, pred = pred, label = label)
}

# -------------------------------------------------------------------
# 1a: AI alone
# -------------------------------------------------------------------

ai_sens <- fit_3L(dat_se_ai,  "ai-alone_sensitivity")
ai_spec <- fit_3L(dat_sp_ai,  "ai-alone_specificity")

# -------------------------------------------------------------------
# 1b: Clinicians alone / AI-assist
# -------------------------------------------------------------------

clin_sens <- fit_3L(dat_se_clin, "clinicians_sensitivity")
clin_spec <- fit_3L(dat_sp_clin, "clinicians_specificity")

assist_sens <- fit_3L(assist_se, "ai-assist_sensitivity")
assist_spec <- fit_3L(assist_sp, "ai-assist_specificity")

# -------------------------------------------------------------------
# Save models + summary table
# -------------------------------------------------------------------

main_models <- list(
  ai_3L_sensitivity       = ai_sens$model,
  ai_3L_specificity       = ai_spec$model,
  clin_3L_sensitivity     = clin_sens$model,
  clin_3L_specificity     = clin_spec$model,
  assist_3L_sensitivity   = assist_sens$model,
  assist_3L_specificity   = assist_spec$model,
  pred_ai_sens            = ai_sens$pred,
  pred_ai_spec            = ai_spec$pred,
  pred_clin_sens          = clin_sens$pred,
  pred_clin_spec          = clin_spec$pred,
  pred_assist_sens        = assist_sens$pred,
  pred_assist_spec        = assist_spec$pred
)

saveRDS(
  main_models,
  file = file.path(paths$out_models, "main_models.rds")
)

# Create a simple summary table (back-transformed)
summ_row <- function(x, comparator, metric) {
  tibble::tibble(
    comparator = comparator,
    metric     = metric,
    est        = x$pred,
    ci_lb      = x$ci.lb,
    ci_ub      = x$ci.ub
  )
}

main_summary <- dplyr::bind_rows(
  summ_row(ai_sens$pred,     "ai-alone",    "sensitivity"),
  summ_row(ai_spec$pred,     "ai-alone",    "specificity"),
  summ_row(clin_sens$pred,   "clinicians",  "sensitivity"),
  summ_row(clin_spec$pred,   "clinicians",  "specificity"),
  summ_row(assist_sens$pred, "ai-assist",   "sensitivity"),
  summ_row(assist_spec$pred, "ai-assist",   "specificity")
)

readr::write_csv(
  main_summary,
  file.path(paths$out_tables, "main_models_summary.csv")
)

message("Main 3-level models fitted and saved.")
