# ==============================
# Second-order meta-analysis for fracture-detection AI
# Author: Rachel Kuo Dec 2025
# ==============================

# Import libraries
library(openxlsx) 
library(readxl)
library(tidyverse)
library(metafor)
library(meta)
library(clubSandwich)
library(wildmeta)
library(glue)
library(dmetar)
library(robumeta)
library(forestploter)
library(grid)

# ==============================

# Input/output 
infile <- "PUTINHERE"
outdir <- "outputs/tables"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# ==============================

# Little helpers
logit  <- function(p) log(p/(1 - p)) #to transform sensitivity/specificity to logits

# Function to estimate SE from CI; safe to use with value 1.00
prep_effects <- function(df, est_col, lo_col, hi_col){ 
  #function prepare effects, take df/name of column/lower 95% CI/upper 95% Ci
  eps <- 1e-6 # Small clip to probabilities away from 0 or 1
  df %>%
    filter(!is.na(.data[[est_col]]), 
           .data[[est_col]] > 0, .data[[est_col]] < 1,
           !is.na(.data[[lo_col]]), !is.na(.data[[hi_col]])) %>%
    # Keep rows only when estimate isn't missing and between 0-1, and 95% CI present
    mutate(
      !!lo_col := pmax(.data[[lo_col]], eps),
      !!hi_col := pmin(.data[[hi_col]], 1 - eps), #clip probs to 1
      #apply logit transforms to:
      yi    = logit(.data[[est_col]]), #point estimate
      yi_lo = logit(.data[[lo_col]]), #lower 95% CI
      yi_hi = logit(.data[[hi_col]]),  #upper 95% CI
      yi_hi = ifelse(yi_hi <= yi_lo, yi_lo + 1e-6, yi_hi), # guard against degen CI logits
      sei   = (yi_hi - yi_lo) / (2*1.96), #derive SE on the logit scale
      vi    = sei^2, #variance on logit scale
      outcome = est_col #save name of measure (sens/spec)
    )
}

# ==============================
# 1a: AI alone 3L model
# ==============================

# Load file
data <- openxlsx::read.xlsx(infile)

# Call prepare effects to transform CI into logits with SE
dat_se <- prep_effects(data, "sens", "sens_ci_low", "sens_ci_high") 
dat_sp <- prep_effects(data, "spec", "spec_ci_low", "spec_ci_high")

# Make row ids for each row nested within a MA (i.e., subgroups)
dat_se <- dat_se %>% mutate(row_id = paste0(meta_id, "_", dplyr::row_number()))
dat_sp <- dat_sp %>% mutate(row_id = paste0(meta_id, "_", dplyr::row_number()))

# Only use AI-alone
dat_se_ai <- dat_se %>% filter(comparator == "ai-alone") %>% droplevels()
dat_sp_ai <- dat_sp %>% filter(comparator == "ai-alone") %>% droplevels()

# Three-level RE (meta_id / row_id)
# Fit two models - one for sens/one for spec
# rma.mv = multi-level meta-analysis

# Sensitivity - AI alone

ai_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = dat_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ai_3L_sensitivity)

prediction_ai_sens <- predict(ai_3L_sensitivity, transf = plogis)
prediction_ai_sens
mean(dat_se_ai$vi)

# Specificity - AI alone

ai_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = dat_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ai_3L_specificity)

prediction_ai_spec <- predict(ai_3L_specificity, transf = plogis)
prediction_ai_spec
mean(dat_sp_ai$vi)

# ==============================
# 1b: Clinician alone / AI-assist 3L model
# ==============================

# Only use clinicians
dat_se_clin <- dat_se %>% filter(comparator == "clinicians") %>% droplevels()
dat_sp_clin <- dat_sp %>% filter(comparator == "clinicians") %>% droplevels()

# Only use AI-assist
assist_se_clin <- dat_se %>% filter(comparator == "ai-assist") %>% droplevels()
assist_sp_clin <- dat_sp %>% filter(comparator == "ai-assist") %>% droplevels()

# Sensitivity - clinicians alone

clin_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = dat_se_clin,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(clin_3L_sensitivity)

predict(clin_3L_sensitivity, transf = plogis)

# Specificity - clinicians alone

clin_3L_specificity <- rma.mv(yi = yi, 
                              V = vi, 
                              slab = meta_id, 
                              data = dat_sp_clin,
                              random = ~ 1 | meta_id/row_id, 
                              test = "t",
                              method = "REML")
summary(clin_3L_specificity)

predict(clin_3L_specificity, transf = plogis)


# Sensitivity - AI-assist 

assist_3L_sensitivity <- rma.mv(yi = yi, 
                              V = vi, 
                              slab = meta_id, 
                              data = assist_se_clin,
                              random = ~ 1 | meta_id/row_id, 
                              test = "t",
                              method = "REML")
summary(assist_3L_sensitivity)

predict(assist_3L_sensitivity, transf = plogis)

# Specificity - AI-assist 

assist_3L_specificity <- rma.mv(yi = yi, 
                                V = vi, 
                                slab = meta_id, 
                                data = assist_sp_clin,
                                random = ~ 1 | meta_id/row_id, 
                                test = "t",
                                method = "REML")
summary(assist_3L_specificity)

predict(assist_3L_specificity, transf = plogis)

# ==============================
# 2: Individual subgroup analyses
# ==============================

# Modality

# Radiographs 
radio_se_ai <- dat_se_ai %>%
  filter(modality == "radiographs") %>%
  droplevels()

radio_sp_ai <- dat_sp_ai %>%
  filter(modality == "radiographs") %>%
  droplevels()

radio_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = radio_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(radio_3L_sensitivity)

predict(radio_3L_sensitivity, transf = plogis)

radio_3L_specificity <- rma.mv(yi = yi, 
                               V = vi, 
                               slab = meta_id, 
                               data = radio_sp_ai,
                               random = ~ 1 | meta_id/row_id, 
                               test = "t",
                               method = "REML")
summary(radio_3L_specificity)

predict(radio_3L_specificity, transf = plogis)



# CT
ct_se_ai <- dat_se_ai %>%
  filter(modality == "ct") %>%
  droplevels()

ct_sp_ai <- dat_sp_ai %>%
  filter(modality == "ct") %>%
  droplevels()

ct_3L_sensitivity <- rma.mv(yi = yi, 
                               V = vi, 
                               slab = meta_id, 
                               data = ct_se_ai,
                               random = ~ 1 | meta_id/row_id, 
                               test = "t",
                               method = "REML")
summary(ct_3L_sensitivity)

predict(ct_3L_sensitivity, transf = plogis)


ct_3L_specificity <- rma.mv(yi = yi, 
                               V = vi, 
                               slab = meta_id, 
                               data = ct_sp_ai,
                               random = ~ 1 | meta_id/row_id, 
                               test = "t",
                               method = "REML")
summary(ct_3L_specificity)

predict(ct_3L_specificity, transf = plogis)


# LOCATION

# Axial 
ax_se_ai <- dat_se_ai %>%
  filter(anatomy == "axial") %>%
  droplevels()

ax_sp_ai <- dat_sp_ai %>%
  filter(anatomy == "axial") %>%
  droplevels()

ax_3L_sensitivity <- rma.mv(yi = yi, 
                               V = vi, 
                               slab = meta_id, 
                               data = ax_se_ai,
                               random = ~ 1 | meta_id/row_id, 
                               test = "t",
                               method = "REML")
summary(ax_3L_sensitivity)

predict(ax_3L_sensitivity, transf = plogis)

ax_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ax_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ax_3L_specificity)

predict(ax_3L_specificity, transf = plogis)


# Lower limb 
ll_se_ai <- dat_se_ai %>%
  filter(anatomy == "lower limb") %>%
  droplevels()

ll_sp_ai <- dat_sp_ai %>%
  filter(anatomy == "lower limb") %>%
  droplevels()

ll_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ll_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ll_3L_sensitivity)
predict(ll_3L_sensitivity, transf = plogis)


ll_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ll_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ll_3L_specificity)

predict(ll_3L_specificity, transf = plogis)

# Upper limb 
ul_se_ai <- dat_se_ai %>%
  filter(anatomy == "upper limb") %>%
  droplevels()

ul_sp_ai <- dat_sp_ai %>%
  filter(anatomy == "upper limb") %>%
  droplevels()

ul_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ul_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ul_3L_sensitivity)
predict(ul_3L_sensitivity, transf = plogis)

ul_sens_ai_i2 <- var.comp(ul_3L_sensitivity)
summary(ul_sens_ai_i2)

ul_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ul_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ul_3L_specificity)

predict(ul_3L_specificity, transf = plogis)
ul_spec_ai_i2 <- var.comp(ul_3L_specificity)
summary(ul_spec_ai_i2)

# Skull 
sk_se_ai <- dat_se_ai %>%
  filter(anatomy == "skull") %>%
  droplevels()

sk_sp_ai <- dat_sp_ai %>%
  filter(anatomy == "skull") %>%
  droplevels()

sk_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = sk_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(sk_3L_sensitivity)
predict(sk_3L_sensitivity, transf = plogis)

sk_sens_ai_i2 <- var.comp(sk_3L_sensitivity)
summary(sk_sens_ai_i2)

sk_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = sk_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(sk_3L_specificity)

predict(sk_3L_specificity, transf = plogis)
sk_spec_ai_i2 <- var.comp(sk_3L_specificity)
summary(sk_spec_ai_i2)

# VALIDATION TYPE

# Internal 

in_se_ai <- dat_se_ai %>%
  filter(validation == "internal") %>%
  droplevels()

in_sp_ai <- dat_sp_ai %>%
  filter(validation == "internal") %>%
  droplevels()

in_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = in_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(in_3L_sensitivity)
predict(in_3L_sensitivity, transf = plogis)
in_sens_ai_i2 <- var.comp(in_3L_sensitivity)
summary(in_sens_ai_i2)

in_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = in_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(in_3L_specificity)

predict(in_3L_specificity, transf = plogis)

in_spec_ai_i2 <- var.comp(in_3L_specificity)
summary(in_spec_ai_i2)


# External 

ex_se_ai <- dat_se_ai %>%
  filter(validation == "external") %>%
  droplevels()

ex_sp_ai <- dat_sp_ai %>%
  filter(validation == "external") %>%
  droplevels()

ex_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ex_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ex_3L_sensitivity)
predict(ex_3L_sensitivity, transf = plogis)
ex_sens_ai_i2 <- var.comp(ex_3L_sensitivity)
summary(ex_sens_ai_i2)


ex_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ex_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ex_3L_specificity)

predict(ex_3L_specificity, transf = plogis)
ex_spec_ai_i2 <- var.comp(ex_3L_specificity)
summary(ex_spec_ai_i2)

# VALIDATION TYPE

# Internal 

in_se_ai <- dat_se_ai %>%
  filter(validation == "internal") %>%
  droplevels()

in_sp_ai <- dat_sp_ai %>%
  filter(validation == "internal") %>%
  droplevels()

in_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = in_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(in_3L_sensitivity)
predict(in_3L_sensitivity, transf = plogis)

in_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = in_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(in_3L_specificity)

predict(in_3L_specificity, transf = plogis)

# POPULATION

# Adults

ad_se_ai <- dat_se_ai %>%
  filter(population == "adults") %>%
  droplevels()

ad_sp_ai <- dat_sp_ai %>%
  filter(population == "adults") %>%
  droplevels()

ad_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ad_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ad_3L_sensitivity)
predict(ad_3L_sensitivity, transf = plogis)


ad_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = ad_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ad_3L_specificity)

predict(ad_3L_specificity, transf = plogis)

# Paediatrics

pa_se_ai <- dat_se_ai %>%
  filter(population == "paediatric") %>%
  droplevels()

pa_sp_ai <- dat_sp_ai %>%
  filter(population == "paediatric") %>%
  droplevels()

pa_3L_sensitivity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = pa_se_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(pa_3L_sensitivity)
predict(pa_3L_sensitivity, transf = plogis)


pa_3L_specificity <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = pa_sp_ai,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(pa_3L_specificity)

predict(pa_3L_specificity, transf = plogis)


# ==============================
# 3: Subgroup analyses: sensitivity
# ==============================

# Make all subgroups factors and set reference level to undifferentiated

dat_se_ai <- dat_se_ai %>%
  mutate(modality = factor(modality),
         modality = relevel(modality, ref = "mixed"))   

dat_se_ai <- dat_se_ai %>%
  mutate(anatomy = factor(anatomy),
         anatomy = relevel(anatomy, ref = "mixed"))   

dat_se_ai <- dat_se_ai %>%
  mutate(validation = factor(validation),
         validation = relevel(validation, ref = "mixed"))   

dat_se_ai <- dat_se_ai %>%
  mutate(population = factor(population),
         population = relevel(population, ref = "mixed"))   

dat_sp_ai <- dat_sp_ai %>%
  mutate(modality = factor(modality),
         modality = relevel(modality, ref = "mixed"))   

dat_sp_ai <- dat_sp_ai %>%
  mutate(anatomy = factor(anatomy),
         anatomy = relevel(anatomy, ref = "mixed"))   

dat_sp_ai <- dat_sp_ai %>%
  mutate(validation = factor(validation),
         validation = relevel(validation, ref = "mixed"))   

dat_sp_ai <- dat_sp_ai %>%
  mutate(population = factor(population),
         population = relevel(population, ref = "mixed"))   


# Three level mixed effects model

mod_se_model <- rma.mv(yi = yi, V = vi, 
                    slab = meta_id,
                    data = dat_se_ai, 
                    random = ~ 1 | meta_id/row_id,
                    test = "t", method = "REML",
                    mods = ~ modality + anatomy + validation + population
                    )
summary(mod_se_model)


mod_sp_model <- rma.mv(yi = yi, V = vi, 
                       slab = meta_id,
                       data = dat_sp_ai, 
                       random = ~ 1 | meta_id/row_id,
                       test = "t", method = "REML",
                       mods = ~ modality + anatomy + validation + population
)
summary(mod_sp_model)

# ==============================
# 2b: RVE: CR2 estimates coefficients
# ==============================

# Set a correlation assumption

rho <- 0.5

Vse <- with(dat_se_ai,
          impute_covariance_matrix(vi = vi, 
                                   cluster = meta_id,
                                   r = rho))

cr2_se_model <- rma.mv(yi ~ 1 + modality + anatomy + validation + population, 
                    V = Vse, 
                    random = ~ 1 | meta_id/row_id,
                    data = dat_se_ai,
                    sparse = TRUE)
conf_int(cr2_se_model,
         vcov = "CR2")
coef_test(cr2_se_model,
         vcov = "CR2")

Vsp <- with(dat_sp_ai,
          impute_covariance_matrix(vi = vi, 
                                   cluster = meta_id,
                                   r = rho))

cr2_sp_model <- rma.mv(yi ~ 1 + modality + anatomy + validation + population, 
                       V = Vsp, 
                       random = ~ 1 | meta_id/row_id,
                       data = dat_sp_ai,
                       sparse = TRUE)
conf_int(cr2_sp_model,
            vcov = "CR2")
coef_test(cr2_sp_model,
             vcov = "CR2")

# Backtransform into sens/spec 

# CR2 CI into df
cr2_sens <- conf_int(cr2_se_model, vcov = "CR2") %>%
  as.data.frame() %>%
  rownames_to_column("term")
cr2_sens

cr2_spec <- conf_int(cr2_sp_model, vcov = "CR2") %>%
  as.data.frame() %>%
  rownames_to_column("term")
cr2_spec

# Back-transform to probability scale
cr2_prob_sens <- cr2_sens %>%
  mutate(
    estimate_prob = plogis(beta),
    ci.lb_prob    = plogis(`CI_L`),
    ci.ub_prob    = plogis(`CI_U`)
  ) %>%
  dplyr::select(term, estimate_prob, ci.lb_prob, ci.ub_prob)

# Back-transform to probability scale
cr2_prob_spec <- cr2_spec %>%
  mutate(
    estimate_prob = plogis(beta),
    ci.lb_prob    = plogis(`CI_L`),
    ci.ub_prob    = plogis(`CI_U`)
  ) %>%
  dplyr::select(term, estimate_prob, ci.lb_prob, ci.ub_prob)

# Print 
cr2_prob_sens %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
cr2_prob_spec %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# ==============================
# 3: Sensitivity analysis: index reviews only
# ==============================

# Beculic, Li, Husarek, Ju, Den Hengst, Nowroozi

target_surnames <- c("beculic","li","husarek","ju","den hengst","nowroozi")

dat_se_ai_index <- dat_se_ai %>%
  filter(str_to_lower(author) %in% target_surnames)

dat_sp_ai_index <- dat_sp_ai %>%
  filter(str_to_lower(author) %in% target_surnames)

# Fit model with index only 

ai_3L_sensitivity_index <- rma.mv(yi = yi, 
                            V = vi, 
                            slab = meta_id, 
                            data = dat_se_ai_index,
                            random = ~ 1 | meta_id/row_id, 
                            test = "t",
                            method = "REML")
summary(ai_3L_sensitivity_index)

predict(ai_3L_sensitivity_index, transf = plogis)



ai_3L_specificity_index <- rma.mv(yi = yi, 
                                  V = vi, 
                                  slab = meta_id, 
                                  data = dat_sp_ai_index,
                                  random = ~ 1 | meta_id/row_id, 
                                  test = "t",
                                  method = "REML")
summary(ai_3L_specificity_index)

predict(ai_3L_specificity_index, transf = plogis)

# ==============================
# 3: Sensitivity analysis: AMSTAR-2 'low' reviews only
# ==============================

# Binh, Hansen, Ju, Jung, Kuo, Li, Nowroozi, Wong, Zhang

target_surnames <- c("binh","hansen","ju","jung","kuo", "li", "nowroozi", "wong", "zhang")

dat_se_ai_amstar <- dat_se_ai %>%
  filter(str_to_lower(author) %in% target_surnames)

dat_sp_ai_amstar <- dat_sp_ai %>%
  filter(str_to_lower(author) %in% target_surnames)

# Fit model with low only 

ai_3L_sensitivity_amstar<- rma.mv(yi = yi, 
                                  V = vi, 
                                  slab = meta_id, 
                                  data = dat_se_ai_amstar,
                                  random = ~ 1 | meta_id/row_id, 
                                  test = "t",
                                  method = "REML")
summary(ai_3L_sensitivity_amstar)

predict(ai_3L_sensitivity_amstar, transf = plogis)

ai_3L_specificity_amstar <- rma.mv(yi = yi, 
                                  V = vi, 
                                  slab = meta_id, 
                                  data = dat_sp_ai_amstar,
                                  random = ~ 1 | meta_id/row_id, 
                                  test = "t",
                                  method = "REML")
summary(ai_3L_specificity_amstar)

predict(ai_3L_specificity_amstar, transf = plogis)


# ==============================
# 4: Forest plots: main comparators
# ==============================

main_forest <- read_excel("/Users/rkuo/Documents/DPhil/Umbrella review/Submission folder/MA_results.xlsx",
                              sheet = "Comparators")

main_forest$'' <-paste(rep(" ", 50), collapse = " ")
main_forest$'Sensitivity (95% CI)' <- ifelse(is.na(main_forest$se_se), "",
                                                 sprintf("%.3f (%.3f to %.3f)",
                                                         main_forest$sens_est,
                                                         main_forest$se_ci_low,
                                                         main_forest$se_ci_hi))

main_forest$'Specificity (95% CI)' <- ifelse(is.na(main_forest$sp_se), "",
                                                 sprintf("%.3f (%.3f to %.3f)",
                                                         main_forest$spec_est,
                                                         main_forest$sp_ci_low,
                                                         main_forest$sp_ci_hi))


# Replace NA with blank or NA will be transformed to character
main_forest$`Number of meta-analyses (primary studies)` <- ifelse(is.na(main_forest$`Number of meta-analyses (primary studies)`),
                                                                      "", main_forest$`Number of meta-analyses (primary studies)`)

main_forest$`Sensitivity` <- ifelse(is.na(main_forest$`Sensitivity`),
                                        "", main_forest$`Sensitivity`)

main_forest$`Specificity` <- ifelse(is.na(main_forest$`Specificity`),
                                        "", main_forest$`Specificity`)

main_forest$`GRADE` <- ifelse(is.na(main_forest$`GRADE`),
                                  "", main_forest$`GRADE`)

main_forest$`Credibility` <- ifelse(is.na(main_forest$`Credibility`),
                                        "", main_forest$`Credibility`)

names(main_forest)[names(main_forest) == "Number of meta-analyses (primary studies)"] <- 
  "Number of\nmeta-analyses\n(primary studies)"

head(main_forest)

tm <- forest_theme(base_size = 10,
                   # Confidence interval point shape, line type/color/width
                   ci_pch = c(15, 19),
                   ci_alpha = 0.8,
                   ci_lty = 1,
                   ci_lwd = 1.5,
                   ci_Theight = 0.4, # Set a T end at the end of CI 
                   ci_col  = c("#3690c0", "#034e7b"),        # Sensitivity = green, Specificity = orange
                   ci_fill = c("#3690c0", "#034e7b"),
                   # Reference line width/type/color
                   refline_gp = gpar(lwd = 1, lty = "dashed", col = "grey20"),
                   # Vertical line width/type/color
                   vertline_lwd = 1,
                   vertline_lty = "dashed",
                   vertline_col = "grey20",
                   # Change summary color for filling and borders
                   core = list(bg_params = list(fill = c("#f7fbff", "white"))),
                   title_just = c("center"),
                   row_height = 2,
                   base_family = "Verdana",
                   #Legends
                   legend_name = "Estimate",
                   legend_pos = "bottom",
                   legend_value = c("Sensitivity",
                                    "Specificity"))


mainp <- forestploter::forest(main_forest[, c(1:2, 20, 21, 22, 18:19)],
                          est = list(main_forest$sens_est,
                                     main_forest$spec_est),
                          lower = list(main_forest$se_ci_low,
                                       main_forest$sp_ci_low),
                          upper = list(main_forest$se_ci_hi,
                                       main_forest$sp_ci_hi),
                          ci_column = 3,
                          nudge_y = 0.6,
                          xlim = c(0.6, 1.),
                          ticks_at = c(0.6, 0.8, 1.0),
                          ref_line = 0.897,
                          theme = tm)

mainp <- edit_plot(mainp, part = "header", gp = gpar(fontface = "bold"))

mainp <- add_border(mainp, part = "header", row = 1, where= "top")
mainp <- add_border(mainp, part = "header", row = 1, where= "bottom")

plot(mainp)

# ==============================
# 4b: Forest plots: subgroups
# ==============================

subgroup_forest <- read_excel("/Users/rkuo/Documents/DPhil/Umbrella review/Submission folder/MA_results.xlsx",
                          sheet = "Subgroups")

subgroup_forest$'' <-paste(rep(" ", 20), collapse = " ")
subgroup_forest$'Sensitivity (95% CI)' <- ifelse(is.na(subgroup_forest$sens_est), "",
                                             sprintf("%.3f (%.3f to %.3f)",
                                                     subgroup_forest$sens_est,
                                                     subgroup_forest$se_ci_low,
                                                     subgroup_forest$se_ci_hi))

subgroup_forest$'Specificity (95% CI)' <- ifelse(is.na(subgroup_forest$spec_est), "",
                                             sprintf("%.3f (%.3f to %.3f)",
                                                     subgroup_forest$spec_est,
                                                     subgroup_forest$sp_ci_low,
                                                     subgroup_forest$sp_ci_hi))


# Replace NA with blank or NA will be transformed to character
subgroup_forest$`Number of meta-analyses (primary studies)` <- ifelse(is.na(subgroup_forest$`Number of meta-analyses (primary studies)`),
                                                "", subgroup_forest$`Number of meta-analyses (primary studies)`)

subgroup_forest$`Sensitivity` <- ifelse(is.na(subgroup_forest$`Sensitivity`),
                                                  "", subgroup_forest$`Sensitivity`)

subgroup_forest$`Specificity` <- ifelse(is.na(subgroup_forest$`Specificity`),
                                "", subgroup_forest$`Specificity`)

subgroup_forest$`GRADE` <- ifelse(is.na(subgroup_forest$`GRADE`),
                                "", subgroup_forest$`GRADE`)

subgroup_forest$`Credibility` <- ifelse(is.na(subgroup_forest$`Credibility`),
                              "", subgroup_forest$`Credibility`)


names(subgroup_forest)[names(subgroup_forest) == "Number of meta-analyses (primary studies)"] <- 
  "Number of meta-analyses\n(primary studies)"


head(subgroup_forest)
  

subp <- forestploter::forest(subgroup_forest[, c(1:2, 20, 21, 22, 18:19)],
                          est = list(subgroup_forest$sens_est,
                                     subgroup_forest$spec_est),
                          lower = list(subgroup_forest$se_ci_low,
                                       subgroup_forest$sp_ci_low),
                          upper = list(subgroup_forest$se_ci_hi,
                                       subgroup_forest$sp_ci_hi),
                          ci_column = 3,
                          nudge_y = 0.6,
                          xlim = c(0.6, 1.),
                          ticks_at = c(0.6, 0.8, 1.0),
                          ref_line = 0.897,
                          theme = tm)

subp <- edit_plot(subp, row= c(1, 6, 11, 14, 17),
               gp = gpar(fontface = "bold"))

subp <- add_border(subp, part = "header", row = 1, where= "top")
subp <- add_border(subp, part = "header", row = 1, where= "bottom")


plot(subp)

# ==============================
# Appendix
# ==============================


# Check 3L model fits better than a 2-level model
# No change in fit - however, 3L represents data more accurately

check_se_3L <- rma.mv(yi = yi, 
                      V = vi, 
                      slab = meta_id, 
                      data = dat_se_ai,
                      random = ~ 1 | meta_id/row_id, 
                      test = "t",
                      method = "REML",
                      sigma2 = c(0, NA))
summary(check_se_3L)
check_se_3L_summary <- with(check_se_3L, c(estimate = plogis(b[1,1]), ci_lb = plogis(ci.lb), ci_ub = plogis(ci.ub)))
check_se_3L_summary

anova(ai_3L_sensitivity, check_se_3L)

check_sp_3L <- rma.mv(yi = yi, 
                      V = vi, 
                      slab = meta_id, 
                      data = dat_sp_ai,
                      random = ~ 1 | meta_id/row_id, 
                      test = "t",
                      method = "REML",
                      sigma2 = c(0, NA))
summary(check_sp_3L)
check_sp_3L_summary <- with(check_sp_3L, c(estimate = plogis(b[1,1]), ci_lb = plogis(ci.lb), ci_ub = plogis(ci.ub)))
check_sp_3L_summary

anova(ai_3L_specificity, check_sp_3L)
