# 05_analysis/R/05_forest_plots.R
# Forest plots: main comparators + subgroups
# Reads from: 05_analysis/data/forest_plots.xlsx

source("analysis/R/0_setup.R")

forest_file <- "data/forest_plots.xlsx"

# Single-meta-analysis subgroups (k = 1): no second-order pool / no PI,
# so their markers and numeric estimates are suppressed.
suppress_labels <- c("MRI", "DEXA")

# Spacer that hosts each CI/PI plot column
spacer <- paste(rep(" ", 30), collapse = " ")

# =====================================================================
# Common theme
#   ci_* graphical params and the legend are indexed by GROUP:
#   group 1 = 95% PI, group 2 = 95% CI. Sensitivity and specificity are
#   already separated into the two ci_columns, not by group.
# =====================================================================

tm <- forestploter::forest_theme(
  base_size    = 10,
  ci_pch       = c(15, 19),                # PI (square) / CI (circle)
  ci_alpha     = 0.8,
  ci_lty       = c(1, 1),
  ci_lwd       = c(1.5, 1.5),
  ci_Theight   = 0.4,                      # T-shaped interval ends
  ci_col       = c("#74a9cf", "#034e7b"),  # 95% PI / 95% CI
  ci_fill      = c("#74a9cf", "#034e7b"),  # 95% PI / 95% CI
  vertline_lwd = 1,
  vertline_lty = "dashed",
  vertline_col = "grey20",
  core         = list(bg_params = list(fill = c("white"))),
  title_just   = c("center"),
  row_height   = 1.5,                      
  legend_name  = "Interval",
  legend_pos   = "bottom",
  legend_value = c("95% PI", "95% CI")     
)

# =====================================================================
# 1. Main comparators forest
# =====================================================================

main_forest <- readxl::read_excel(
  forest_file,
  sheet = "Comparators"
)

drop_main <- trimws(as.character(main_forest[[1]])) %in% suppress_labels

# Pretty estimate / CI / PI strings (blank where no estimate or no PI)
main_forest$`Sensitivity Estimate` <- ifelse(
  is.na(main_forest$sens_est),
  "",
  sprintf("%.3f", main_forest$sens_est)
)

main_forest$`Sensitivity (95% CI)` <- ifelse(
  is.na(main_forest$sens_est),
  "",
  sprintf("%.3f to %.3f", main_forest$se_ci_low, main_forest$se_ci_hi)
)

main_forest$`Sensitivity (95% PI)` <- ifelse(
  is.na(main_forest$sens_est) | is.na(main_forest$se_pi_low),
  "",
  sprintf("%.3f to %.3f", main_forest$se_pi_low, main_forest$se_pi_hi)
)

main_forest$`Specificity Estimate` <- ifelse(
  is.na(main_forest$spec_est),
  "",
  sprintf("%.3f", main_forest$spec_est)
)

main_forest$`Specificity (95% CI)` <- ifelse(
  is.na(main_forest$spec_est),
  "",
  sprintf("%.3f to %.3f", main_forest$sp_ci_low, main_forest$sp_ci_hi)
)

main_forest$`Specificity (95% PI)` <- ifelse(
  is.na(main_forest$spec_est) | is.na(main_forest$sp_pi_low),
  "",
  sprintf("%.3f to %.3f", main_forest$sp_pi_low, main_forest$sp_pi_hi)
)

# Blank numeric estimate columns for suppressed (single-MA) rows
for (cc in c("Sensitivity Estimate", "Sensitivity (95% CI)", "Sensitivity (95% PI)",
             "Specificity Estimate", "Specificity (95% CI)", "Specificity (95% PI)")) {
  main_forest[[cc]][drop_main] <- ""
}

# Replace NA with blank for the remaining text columns
for (col in c("GRADE", "Credibility", "Number of meta-analyses (primary studies)")) {
  main_forest[[col]] <- ifelse(is.na(main_forest[[col]]), "", main_forest[[col]])
}

# Spacer columns that host the two CI/PI plots
main_forest$Sensitivity <- spacer
main_forest$Specificity <- spacer

# Display data frame (12 columns)
disp_main <- data.frame(
  check.names = FALSE,
  Subgroup                                     = main_forest[[1]],
  GRADE                                        = main_forest$GRADE,
  Credibility                                  = main_forest$Credibility,
  `Number of meta-analyses\n(primary studies)` = main_forest$`Number of meta-analyses (primary studies)`,
  Sensitivity                                  = main_forest$Sensitivity,             # col 5  (plot 1)
  `Sensitivity`                                = main_forest$`Sensitivity Estimate`,   # col 6
  `95% CI`                                     = main_forest$`Sensitivity (95% CI)`,   # col 7
  `95% PI`                                     = main_forest$`Sensitivity (95% PI)`,   # col 8
  Specificity                                  = main_forest$Specificity,             # col 9  (plot 2)
  `Specificity`                                = main_forest$`Specificity Estimate`,   # col 10
  `95% CI`                                     = main_forest$`Specificity (95% CI)`,   # col 11
  `95% PI`                                     = main_forest$`Specificity (95% PI)`    # col 12
)

# NA-out plotted estimates for suppressed rows (forestploter skips NA series)
main_sens  <- main_forest$sens_est;  main_spec  <- main_forest$spec_est
main_se_pl <- main_forest$se_pi_low; main_se_ph <- main_forest$se_pi_hi
main_se_cl <- main_forest$se_ci_low; main_se_ch <- main_forest$se_ci_hi
main_sp_pl <- main_forest$sp_pi_low; main_sp_ph <- main_forest$sp_pi_hi
main_sp_cl <- main_forest$sp_ci_low; main_sp_ch <- main_forest$sp_ci_hi

main_sens[drop_main]  <- NA; main_spec[drop_main]  <- NA
main_se_pl[drop_main] <- NA; main_se_ph[drop_main] <- NA
main_se_cl[drop_main] <- NA; main_se_ch[drop_main] <- NA
main_sp_pl[drop_main] <- NA; main_sp_ph[drop_main] <- NA
main_sp_cl[drop_main] <- NA; main_sp_ch[drop_main] <- NA

# Build forest

mainp <- forestploter::forest(
  disp_main,
  est = list(
    main_sens,  main_spec,    # group 1 = PI
    main_sens,  main_spec     # group 2 = CI
  ),
  lower = list(
    main_se_pl, main_sp_pl,   # PI lowers
    main_se_cl, main_sp_cl    # CI lowers
  ),
  upper = list(
    main_se_ph, main_sp_ph,   # PI uppers
    main_se_ch, main_sp_ch    # CI uppers
  ),
  ci_column = c(5, 9),
  nudge_y   = 0,
  xlim      = c(0.6, 1.0),
  ticks_at  = c(0.6, 0.8, 1.0),
  theme     = tm
)

# GRADE / Credibility background highlights
main_green_grade  <- which(trimws(tolower(disp_main$GRADE)) == "moderate")
main_amber_grade  <- which(trimws(tolower(disp_main$GRADE)) == "low")
main_maroon_grade <- which(trimws(tolower(disp_main$GRADE)) == "very low")

main_amber_cred   <- which(trimws(disp_main$Credibility) == "III")
main_maroon_cred  <- which(trimws(disp_main$Credibility) == "IV")
main_darkred_cred <- which(trimws(disp_main$Credibility) == "V")

if (length(main_green_grade))  mainp <- forestploter::edit_plot(mainp, row = main_green_grade,  col = 2, which = "background", gp = grid::gpar(fill = "#D1E7DD"))
if (length(main_amber_grade))  mainp <- forestploter::edit_plot(mainp, row = main_amber_grade,  col = 2, which = "background", gp = grid::gpar(fill = "#FFF3CD"))
if (length(main_maroon_grade)) mainp <- forestploter::edit_plot(mainp, row = main_maroon_grade, col = 2, which = "background", gp = grid::gpar(fill = "#F8D7DA"))

if (length(main_amber_cred))   mainp <- forestploter::edit_plot(mainp, row = main_amber_cred,   col = 3, which = "background", gp = grid::gpar(fill = "#FFF3CD"))
if (length(main_maroon_cred))  mainp <- forestploter::edit_plot(mainp, row = main_maroon_cred,  col = 3, which = "background", gp = grid::gpar(fill = "#F8D7DA"))
if (length(main_darkred_cred)) mainp <- forestploter::edit_plot(mainp, row = main_darkred_cred, col = 3, which = "background", gp = grid::gpar(fill = "#F1AEB5"))

# Header: bold titles, spanning super-headers, borders
mainp <- forestploter::edit_plot(mainp, part = "header",
                                 gp = grid::gpar(fontface = "bold"))

mainp <- forestploter::insert_text(
  mainp,
  text = "Strength of the evidence",
  col  = 2:4,
  part = "header",
  just = "center",
  gp   = grid::gpar(fontface = "bold")
)

mainp <- forestploter::add_text(
  mainp,
  text = "Pooled diagnostic accuracy estimates",
  row  = 1,
  col  = 5:12,
  part = "header",
  just = "center",
  gp   = grid::gpar(fontface = "bold")
)

mainp <- forestploter::add_border(mainp, part = "header", row = 1, where = "top")
mainp <- forestploter::add_border(mainp, part = "header", row = 2, where = "bottom")
mainp <- forestploter::add_border(mainp, part = "header", row = 1, col = 2:4,  where = "bottom")
mainp <- forestploter::add_border(mainp, part = "header", row = 1, col = 5:12, where = "bottom")

# Save main comparators figure
pdf(file.path(paths$out_plots, "fig1_forest_main_comparators.pdf"),
    width = 17, height = 5)
plot(mainp)
dev.off()

png(file.path(paths$out_plots, "fig1_forest_main_comparators.png"),
    width = 5000, height = 1450, res = 300)
plot(mainp)
dev.off()

# =====================================================================
# 2. Subgroups forest
# =====================================================================

subgroup_forest <- readxl::read_excel(
  forest_file,
  sheet = "Subgroups"
)

drop_sub <- trimws(as.character(subgroup_forest[[1]])) %in% suppress_labels

# Pretty estimate / CI / PI strings (blank where no estimate or no PI)
subgroup_forest$`Sensitivity Estimate` <- ifelse(
  is.na(subgroup_forest$sens_est),
  "",
  sprintf("%.3f", subgroup_forest$sens_est)
)

subgroup_forest$`Sensitivity (95% CI)` <- ifelse(
  is.na(subgroup_forest$sens_est),
  "",
  sprintf("%.3f to %.3f", subgroup_forest$se_ci_low, subgroup_forest$se_ci_hi)
)

subgroup_forest$`Sensitivity (95% PI)` <- ifelse(
  is.na(subgroup_forest$sens_est) | is.na(subgroup_forest$se_pi_low),
  "",
  sprintf("%.3f to %.3f", subgroup_forest$se_pi_low, subgroup_forest$se_pi_hi)
)

subgroup_forest$`Specificity Estimate` <- ifelse(
  is.na(subgroup_forest$spec_est),
  "",
  sprintf("%.3f", subgroup_forest$spec_est)
)

subgroup_forest$`Specificity (95% CI)` <- ifelse(
  is.na(subgroup_forest$spec_est),
  "",
  sprintf("%.3f to %.3f", subgroup_forest$sp_ci_low, subgroup_forest$sp_ci_hi)
)

subgroup_forest$`Specificity (95% PI)` <- ifelse(
  is.na(subgroup_forest$spec_est) | is.na(subgroup_forest$sp_pi_low),
  "",
  sprintf("%.3f to %.3f", subgroup_forest$sp_pi_low, subgroup_forest$sp_pi_hi)
)

# Blank numeric estimate columns for suppressed (single-MA) rows
for (cc in c("Sensitivity Estimate", "Sensitivity (95% CI)", "Sensitivity (95% PI)",
             "Specificity Estimate", "Specificity (95% CI)", "Specificity (95% PI)")) {
  subgroup_forest[[cc]][drop_sub] <- ""
}

# Replace NA with blank for the remaining text columns
for (col in c("GRADE", "Credibility", "Number of meta-analyses (primary studies)")) {
  subgroup_forest[[col]] <- ifelse(is.na(subgroup_forest[[col]]), "", subgroup_forest[[col]])
}

# Spacer columns that host the two CI/PI plots
subgroup_forest$Sensitivity <- spacer
subgroup_forest$Specificity <- spacer

# Display data frame (12 columns)
disp_sub <- data.frame(
  check.names = FALSE,
  Subgroup                                     = subgroup_forest[[1]],
  GRADE                                        = subgroup_forest$GRADE,
  Credibility                                  = subgroup_forest$Credibility,
  `Number of meta-analyses\n(primary studies)` = subgroup_forest$`Number of meta-analyses (primary studies)`,
  Sensitivity                                  = subgroup_forest$Sensitivity,             # col 5  (plot 1)
  `Sensitivity`                                = subgroup_forest$`Sensitivity Estimate`,   # col 6
  `95% CI`                                     = subgroup_forest$`Sensitivity (95% CI)`,   # col 7
  `95% PI`                                     = subgroup_forest$`Sensitivity (95% PI)`,   # col 8
  Specificity                                  = subgroup_forest$Specificity,             # col 9  (plot 2)
  `Specificity`                                = subgroup_forest$`Specificity Estimate`,   # col 10
  `95% CI`                                     = subgroup_forest$`Specificity (95% CI)`,   # col 11
  `95% PI`                                     = subgroup_forest$`Specificity (95% PI)`    # col 12
)

# NA-out plotted estimates for suppressed rows (forestploter skips NA series)
sub_sens  <- subgroup_forest$sens_est;  sub_spec  <- subgroup_forest$spec_est
sub_se_pl <- subgroup_forest$se_pi_low; sub_se_ph <- subgroup_forest$se_pi_hi
sub_se_cl <- subgroup_forest$se_ci_low; sub_se_ch <- subgroup_forest$se_ci_hi
sub_sp_pl <- subgroup_forest$sp_pi_low; sub_sp_ph <- subgroup_forest$sp_pi_hi
sub_sp_cl <- subgroup_forest$sp_ci_low; sub_sp_ch <- subgroup_forest$sp_ci_hi

sub_sens[drop_sub]  <- NA; sub_spec[drop_sub]  <- NA
sub_se_pl[drop_sub] <- NA; sub_se_ph[drop_sub] <- NA
sub_se_cl[drop_sub] <- NA; sub_se_ch[drop_sub] <- NA
sub_sp_pl[drop_sub] <- NA; sub_sp_ph[drop_sub] <- NA
sub_sp_cl[drop_sub] <- NA; sub_sp_ch[drop_sub] <- NA

# Build forest
#   list order is column-cycling: col5/g1, col9/g1, col5/g2, col9/g2
#   => group 1 = 95% PI, group 2 = 95% CI, nested within each measure column
subp <- forestploter::forest(
  disp_sub,
  est = list(
    sub_sens,  sub_spec,     # group 1 = PI
    sub_sens,  sub_spec      # group 2 = CI
  ),
  lower = list(
    sub_se_pl, sub_sp_pl,    # PI lowers
    sub_se_cl, sub_sp_cl     # CI lowers
  ),
  upper = list(
    sub_se_ph, sub_sp_ph,    # PI uppers
    sub_se_ch, sub_sp_ch     # CI uppers
  ),
  ci_column = c(5, 9),
  nudge_y   = 0,
  xlim      = c(0.6, 1.0),
  ticks_at  = c(0.6, 0.8, 1.0),
  theme     = tm
)

# GRADE / Credibility background highlights
sub_green_grade  <- which(trimws(tolower(disp_sub$GRADE)) == "moderate")
sub_amber_grade  <- which(trimws(tolower(disp_sub$GRADE)) == "low")
sub_maroon_grade <- which(trimws(tolower(disp_sub$GRADE)) == "very low")

sub_amber_cred   <- which(trimws(disp_sub$Credibility) == "III")
sub_maroon_cred  <- which(trimws(disp_sub$Credibility) == "IV")
sub_darkred_cred <- which(trimws(disp_sub$Credibility) == "V")

if (length(sub_green_grade))  subp <- forestploter::edit_plot(subp, row = sub_green_grade,  col = 2, which = "background", gp = grid::gpar(fill = "#D1E7DD"))
if (length(sub_amber_grade))  subp <- forestploter::edit_plot(subp, row = sub_amber_grade,  col = 2, which = "background", gp = grid::gpar(fill = "#FFF3CD"))
if (length(sub_maroon_grade)) subp <- forestploter::edit_plot(subp, row = sub_maroon_grade, col = 2, which = "background", gp = grid::gpar(fill = "#F8D7DA"))

if (length(sub_amber_cred))   subp <- forestploter::edit_plot(subp, row = sub_amber_cred,   col = 3, which = "background", gp = grid::gpar(fill = "#FFF3CD"))
if (length(sub_maroon_cred))  subp <- forestploter::edit_plot(subp, row = sub_maroon_cred,  col = 3, which = "background", gp = grid::gpar(fill = "#F8D7DA"))
if (length(sub_darkred_cred)) subp <- forestploter::edit_plot(subp, row = sub_darkred_cred, col = 3, which = "background", gp = grid::gpar(fill = "#F1AEB5"))

# Bold the subgroup divider rows (Modality / Fracture location / Validation / Population)
subp <- forestploter::edit_plot(
  subp,
  row = c(1, 6, 11, 14, 17),   # adjust indices if your sheet differs
  gp  = grid::gpar(fontface = "bold")
)

# Header: bold titles, spanning super-headers, borders
subp <- forestploter::edit_plot(subp, part = "header",
                                gp = grid::gpar(fontface = "bold"))

subp <- forestploter::insert_text(
  subp,
  text = "Strength of the evidence",
  col  = 2:4,
  part = "header",
  just = "center",
  gp   = grid::gpar(fontface = "bold")
)

subp <- forestploter::add_text(
  subp,
  text = "Pooled diagnostic accuracy estimates",
  row  = 1,
  col  = 5:12,
  part = "header",
  just = "center",
  gp   = grid::gpar(fontface = "bold")
)

subp <- forestploter::add_border(subp, part = "header", row = 1, where = "top")
subp <- forestploter::add_border(subp, part = "header", row = 2, where = "bottom")
subp <- forestploter::add_border(subp, part = "header", row = 1, col = 2:4,  where = "bottom")
subp <- forestploter::add_border(subp, part = "header", row = 1, col = 5:12, where = "bottom")

# Save subgroup figure (bigger device so all rows/legend fit)
pdf(file.path(paths$out_plots, "figS1_forest_subgroups.pdf"),
    width = 17, height = 10)
plot(subp)
dev.off()

png(file.path(paths$out_plots, "figS1_forest_subgroups.png"),
    width = 5000, height = 3200, res = 300)
plot(subp)
dev.off()

message("Forest plots from forest_plots.xlsx (Comparators + Subgroups) generated.")