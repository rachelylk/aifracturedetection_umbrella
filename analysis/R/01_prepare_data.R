# analysis/R/01_prepare_data.R
source("analysis/R/0_setup.R")

# Load data ---------------------------------------------------------------

message("Loading meta-analysis dataset: ", paths$ma_results)

data <- readxl::read_excel(paths$ma_results)

# Prepare sensitivity + specificity datasets ------------------------------

dat_se <- prep_effects(data, "sens", "sens_ci_low", "sens_ci_high") %>%
  mutate(row_id = paste0(meta_id, "_", row_number()))

dat_sp <- prep_effects(data, "spec", "spec_ci_low", "spec_ci_high") %>%
  mutate(row_id = paste0(meta_id, "_", row_number()))

# Split by comparator ------------------------------------------------------

dat_se_ai  <- dat_se %>% filter(comparator == "ai-alone") %>% droplevels()
dat_sp_ai  <- dat_sp %>% filter(comparator == "ai-alone") %>% droplevels()

dat_se_clin <- dat_se %>% filter(comparator == "clinicians") %>% droplevels()
dat_sp_clin <- dat_sp %>% filter(comparator == "clinicians") %>% droplevels()

assist_se <- dat_se %>% filter(comparator == "ai-assist") %>% droplevels()
assist_sp <- dat_sp %>% filter(comparator == "ai-assist") %>% droplevels()

# Save data objects --------------------------------------------------------

saveRDS(
  list(
    data       = data,
    dat_se     = dat_se,
    dat_sp     = dat_sp,
    dat_se_ai  = dat_se_ai,
    dat_sp_ai  = dat_sp_ai,
    dat_se_clin = dat_se_clin,
    dat_sp_clin = dat_sp_clin,
    assist_se   = assist_se,
    assist_sp   = assist_sp
  ),
  file = file.path(paths$out_models, "prepared_data.rds")
)

message("Data prep complete.")
