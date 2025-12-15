# analysis/R/4_sensitivity_analyses.R
# Sensitivity analyses: index reviews only & AMSTAR-2 'low' reviews

source("analysis/R/0_setup.R")

dat_list <- readRDS(file.path(paths$out_models, "prepared_data.rds"))

dat_se_ai <- dat_list$dat_se_ai
dat_sp_ai <- dat_list$dat_sp_ai

fit_and_summarise <- function(dat, label) {
  if (nrow(dat) == 0) return(NULL)
  m <- rma.mv(
    yi = yi,
    V  = vi,
    slab = meta_id,
    data = dat,
    random = ~ 1 | meta_id/row_id,
    test   = "t",
    method = "REML"
  )
  pred <- predict(m, transf = plogis)
  tibble::tibble(
    label  = label,
    n_rows = nrow(dat),
    est    = pred$pred,
    ci_lb  = pred$ci.lb,
    ci_ub  = pred$ci.ub
  )
}

# -------------------------------------------------------------------
# 3: Sensitivity analysis – index reviews only
# Beculic,Li, Husarek, Ju, Den Hengst,Nowroozi
# -------------------------------------------------------------------

index_authors <- c("beculic","li","husarek","ju","den hengst","nowroozi")

dat_se_ai_index <- dat_se_ai %>%
  dplyr::filter(stringr::str_to_lower(author) %in% index_authors)

dat_sp_ai_index <- dat_sp_ai %>%
  dplyr::filter(stringr::str_to_lower(author) %in% index_authors)

sens_index <- fit_and_summarise(dat_se_ai_index, "index_ai_sensitivity")
spec_index <- fit_and_summarise(dat_sp_ai_index, "index_ai_specificity")

# -------------------------------------------------------------------
# 3: Sensitivity analysis – AMSTAR-2 'low' reviews only
# Ju, Jung, Kuo, Li, van den Broek, Wong, Zhang
# -------------------------------------------------------------------

amstar_authors <- c("ju","jung","kuo", "li", "van den broek", "wong", "zhang")

dat_se_ai_amstar <- dat_se_ai %>%
  dplyr::filter(stringr::str_to_lower(author) %in% amstar_authors)

dat_sp_ai_amstar <- dat_sp_ai %>%
  dplyr::filter(stringr::str_to_lower(author) %in% amstar_authors)

sens_amstar <- fit_and_summarise(dat_se_ai_amstar, "amstar_low_ai_sensitivity")
spec_amstar <- fit_and_summarise(dat_sp_ai_amstar, "amstar_low_ai_specificity")

sens_table <- dplyr::bind_rows(sens_index, sens_amstar)
spec_table <- dplyr::bind_rows(spec_index, spec_amstar)

readr::write_csv(
  sens_table,
  file.path(paths$out_tables, "sensitivity_analyses_sensitivity.csv")
)

readr::write_csv(
  spec_table,
  file.path(paths$out_tables, "sensitivity_analyses_specificity.csv")
)

message("Sensitivity analyses (index + AMSTAR low) completed.")
