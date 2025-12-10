# analysis/R/0_setup.R
# ==============================
# Setup for umbrella meta-analysis
# ==============================

# Libraries ---------------------------------------------------------------
library(readxl)
library(openxlsx)
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

# Paths -------------------------------------------------------------------
paths <- list(
  ma_results  = "analysis/data/ma_results.xlsx",       
  out_tables  = "analysis/results/tables",
  out_models  = "analysis/results/models",
  out_plots   = "figures_tables/figs_main"
)

# Create directories if missing
dir.create(paths$out_tables, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$out_models, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$out_plots,  showWarnings = FALSE, recursive = TRUE)

# Helper functions ---------------------------------------------------------

logit <- function(p) log(p/(1 - p))

prep_effects <- function(df, est_col, lo_col, hi_col){
  eps <- 1e-6
  df %>%
    filter(
      !is.na(.data[[est_col]]),
      .data[[est_col]] > 0, .data[[est_col]] < 1,
      !is.na(.data[[lo_col]]),
      !is.na(.data[[hi_col]])
    ) %>%
    mutate(
      !!lo_col := pmax(.data[[lo_col]], eps),
      !!hi_col := pmin(.data[[hi_col]], 1 - eps),
      yi    = logit(.data[[est_col]]),
      yi_lo = logit(.data[[lo_col]]),
      yi_hi = logit(.data[[hi_col]]),
      yi_hi = ifelse(yi_hi <= yi_lo, yi_lo + 1e-6, yi_hi),
      sei   = (yi_hi - yi_lo) / (2*1.96),
      vi    = sei^2,
      outcome = est_col
    )
}
