# 05_analysis/R/05_forest_plots.R
# Forest plots: main comparators + subgroups
# Reads from: 05_analysis/data/forest_plots.xlsx

source("analysis/R/0_setup.R")

forest_file <- "data/forest_plots.xlsx"

# =====================================================================
# Common theme 
# =====================================================================

tm <- forestploter::forest_theme(
  base_size    = 10,
  ci_pch       = c(15, 19),
  ci_alpha     = 0.8,
  ci_lty       = 1,
  ci_lwd       = 1.5,
  ci_Theight   = 0.4,                      # T-shaped CI ends
  ci_col       = c("#3690c0", "#034e7b"),  # Sensitivity / Specificity
  ci_fill      = c("#3690c0", "#034e7b"),
  refline_gp   = grid::gpar(lwd = 1, lty = "dashed", col = "grey20"),
  vertline_lwd = 1,
  vertline_lty = "dashed",
  vertline_col = "grey20",
  core         = list(bg_params = list(fill = c("#f7fbff", "white"))),
  title_just   = c("center"),
  row_height   = 1.5,                      # slightly tighter so more rows fit
  legend_name  = "Estimate",
  legend_pos   = "bottom",
  legend_value = c("Sensitivity", "Specificity")
)

# =====================================================================
# 1. Main comparators forest
# =====================================================================

main_forest <- readxl::read_excel(
  forest_file,
  sheet = "Comparators"
)

# Spacer column for layout
main_forest$'' <- paste(rep(" ", 50), collapse = " ")

# Pretty CI strings
main_forest$`Sensitivity (95% CI)` <- ifelse(
  is.na(main_forest$se_se),
  "",
  sprintf("%.3f (%.3f to %.3f)",
          main_forest$sens_est,
          main_forest$se_ci_low,
          main_forest$se_ci_hi)
)

main_forest$`Specificity (95% CI)` <- ifelse(
  is.na(main_forest$sp_se),
  "",
  sprintf("%.3f (%.3f to %.3f)",
          main_forest$spec_est,
          main_forest$sp_ci_low,
          main_forest$sp_ci_hi)
)

# Replace NA with blank for text columns
main_forest$`Number of meta-analyses (primary studies)` <- ifelse(
  is.na(main_forest$`Number of meta-analyses (primary studies)`),
  "", main_forest$`Number of meta-analyses (primary studies)`
)

main_forest$`Sensitivity` <- ifelse(
  is.na(main_forest$`Sensitivity`),
  "", main_forest$`Sensitivity`
)

main_forest$`Specificity` <- ifelse(
  is.na(main_forest$`Specificity`),
  "", main_forest$`Specificity`
)

main_forest$`GRADE` <- ifelse(
  is.na(main_forest$`GRADE`),
  "", main_forest$`GRADE`
)

main_forest$`Credibility` <- ifelse(
  is.na(main_forest$`Credibility`),
  "", main_forest$`Credibility`
)

# Wrap header for N meta-analyses
names(main_forest)[names(main_forest) ==
                     "Number of meta-analyses (primary studies)"] <-
  "Number of\nmeta-analyses\n(primary studies)"

# Build forest (column indices assume same layout as your original file)
mainp <- forestploter::forest(
  main_forest[, c(1:2, 20, 21, 22, 18:19)],
  est = list(
    main_forest$sens_est,
    main_forest$spec_est
  ),
  lower = list(
    main_forest$se_ci_low,
    main_forest$sp_ci_low
  ),
  upper = list(
    main_forest$se_ci_hi,
    main_forest$sp_ci_hi
  ),
  ci_column = 3,
  nudge_y   = 0.6,
  xlim      = c(0.6, 1.0),
  ticks_at  = c(0.6, 0.8, 1.0),
  ref_line  = 0.897,  # your pooled AI-alone sensitivity; tweak if needed
  theme     = tm
)

mainp <- forestploter::edit_plot(
  mainp,
  part = "header",
  gp   = grid::gpar(fontface = "bold")
)

mainp <- forestploter::add_border(mainp, part = "header",
                                  row = 1, where = "top")
mainp <- forestploter::add_border(mainp, part = "header",
                                  row = 1, where = "bottom")

# Save main comparators figure (larger device so nothing is clipped)
pdf(file.path(paths$out_plots, "fig1_forest_main_comparators.pdf"),
    width = 12, height = 4.5)
plot(mainp)
dev.off()

png(file.path(paths$out_plots, "fig1_forest_main_comparators.png"),
    width = 3500, height = 1300, res = 300)
plot(mainp)
dev.off()

# =====================================================================
# 2. Subgroups forest
# =====================================================================

subgroup_forest <- readxl::read_excel(
  forest_file,
  sheet = "Subgroups"
)

subgroup_forest$'' <- paste(rep(" ", 20), collapse = " ")

subgroup_forest$`Sensitivity (95% CI)` <- ifelse(
  is.na(subgroup_forest$sens_est),
  "",
  sprintf("%.3f (%.3f to %.3f)",
          subgroup_forest$sens_est,
          subgroup_forest$se_ci_low,
          subgroup_forest$se_ci_hi)
)

subgroup_forest$`Specificity (95% CI)` <- ifelse(
  is.na(subgroup_forest$spec_est),
  "",
  sprintf("%.3f (%.3f to %.3f)",
          subgroup_forest$spec_est,
          subgroup_forest$sp_ci_low,
          subgroup_forest$sp_ci_hi)
)

subgroup_forest$`Number of meta-analyses (primary studies)` <- ifelse(
  is.na(subgroup_forest$`Number of meta-analyses (primary studies)`),
  "", subgroup_forest$`Number of meta-analyses (primary studies)`
)

subgroup_forest$`Sensitivity` <- ifelse(
  is.na(subgroup_forest$`Sensitivity`),
  "", subgroup_forest$`Sensitivity`
)

subgroup_forest$`Specificity` <- ifelse(
  is.na(subgroup_forest$`Specificity`),
  "", subgroup_forest$`Specificity`
)

subgroup_forest$`GRADE` <- ifelse(
  is.na(subgroup_forest$`GRADE`),
  "", subgroup_forest$`GRADE`
)

subgroup_forest$`Credibility` <- ifelse(
  is.na(subgroup_forest$`Credibility`),
  "", subgroup_forest$`Credibility`
)

names(subgroup_forest)[names(subgroup_forest) ==
                         "Number of meta-analyses (primary studies)"] <-
  "Number of meta-analyses\n(primary studies)"

# Build subgroup forest
subp <- forestploter::forest(
  subgroup_forest[, c(1:2, 20, 21, 22, 18:19)],
  est = list(
    subgroup_forest$sens_est,
    subgroup_forest$spec_est
  ),
  lower = list(
    subgroup_forest$se_ci_low,
    subgroup_forest$sp_ci_low
  ),
  upper = list(
    subgroup_forest$se_ci_hi,
    subgroup_forest$sp_ci_hi
  ),
  ci_column = 3,
  nudge_y   = 0.6,
  xlim      = c(0.6, 1.0),
  ticks_at  = c(0.6, 0.8, 1.0),
  ref_line  = 0.897,
  theme     = tm
)

# Bold specific subgroup header rows (as in your original):
subp <- forestploter::edit_plot(
  subp,
  row = c(1, 6, 11, 14, 17),   # adjust indices if your sheet differs
  gp  = grid::gpar(fontface = "bold")
)

subp <- forestploter::add_border(subp, part = "header",
                                 row = 1, where = "top")
subp <- forestploter::add_border(subp, part = "header",
                                 row = 1, where = "bottom")

# Save subgroup figure (bigger device so all rows/legend fit)
pdf(file.path(paths$out_plots, "figS1_forest_subgroups.pdf"),
    width = 12, height = 10)
plot(subp)
dev.off()

png(file.path(paths$out_plots, "figS1_forest_subgroups.png"),
    width = 3500, height = 3200, res = 300)
plot(subp)
dev.off()

message("Forest plots from forest_plots.xlsx (Comparators + Subgroups) generated.")
