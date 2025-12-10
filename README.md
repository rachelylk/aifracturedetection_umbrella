# Performance of artificial intelligence for fracture detection: an overview of reviews and second-order meta-analysis

This repository contains the data, code, and supplementary material for the paper:

**“Performance of artificial intelligence for fracture detection: an overview of reviews and second-order meta-analysis.”**  
Rachel Kuo*, Ciaran O'Hanlon*, Alexander Freethy*, Catriona Stoddart,Sophie Ludbrook, Alan Hasanic, Eli Harriss, Dominic Furniss, Gary S Collins

*Joint first authorship

-to add full citation-

---

## License 
- License: MIT 
- DOI: *to fill in*

---

# Table of contents
- [Overview](#overview)
- [Citation](#citation)
- [Repository structure](#repository-structure)
- [Quickstart](#quickstart)
- [Reproducing key results](#reproducing-key-results)
- [Scripts and workflows](#scripts-and-workflows)
- [Data](#data)
- [Output and figures](#output-and-figures)
- [Supplement](#supplement)
- [Required R packages](#rpackages)
- [How to cite](#how-to-cite)
- [Generative AI declaration](#gen-ai)
- [Contact](#contact)

---

# Overview

This repository contains the complete analysis pipeline used in the umbrella review and second-order meta-analysis assessing the diagnostic performance of artificial intelligence (AI) for fracture detection.  

The repo provides:

- R code for all analyses  
- Datasets  
- Three-level random-effects models  
- Moderator and subgroup analyses  
- Robust variance estimation (CR2)  
- Sensitivity analyses  
- Forest plots and appendix model checks
  
---

# Citation

Please cite the manuscript when using results or code from this repository.

**to fill in**

---


## Repository structure

```bash
aifracturedetection_umbrella/
├── analysis/
│   ├── R/
│   │   ├── 0_setup.R
│   │   ├── 1_prepare_data.R
│   │   ├── 2_models_main.R
│   │   ├── 3_models_subgroups_RVE.R
│   │   ├── 4_sensitivity_analyses.R
│   │   ├── 5_forest_plots.R
│   │   ├── 6_check3Lmodelfit.R
│   │   └── 00_run_all.R  # run whole pipeline
│   ├── data/
│   │   ├── ma_results.xlsx # extracted dataset for included meta-analyses
│   │   └── forest_plots.xlsx # data to produce Forest plots
│   └── figures_tables/
│       ├── figs_main/
├── supplement/
│   ├── 2_database_searches
│   ├── 3_excluded_papers
│   ├── 4_meta_analysis_GROOVE
│   ├── 5_systematic_review_GROOVE
│   ├── 6_secondorderma_code.R
│   ├── 7_ma_data_sensitivity_analyses
├── README.md
└── LICENSE
```
---

# Quickstart

First, clone the repository: 
git clone https://github.com/rachelylk/aifracturedetection_umbrella.git

Open R in the repo root, or set your own working directory. 

Then, run the entire pipeline:
```source("analysis/run_all.R")```

---
# Reproducing key results

## Primary analyses

To run the primary analyses, use: 

```source("analysis/R/2_models_main.R")```

This script fits three-level random-effects models for:
- AI-alone sensitivity and specificity
- Clinicians-alone
- AI-assisted clinicians

Then, back-transforms estimates to probability scale and finally saves model objects and tables into results/

## Subgroup and moderator analyses

To run the subgroup and moderator analyses, use: 

```source("analysis/R/3_models_subgroups_RVE.R")```

This script fits moderator models (modality, anatomy, validation type, population), computes robust CR2 RVE estimates and exports tables for the manuscript

## Sensitivity analyses

To run the described sensitivity analyses, use: 

```source("analysis/R/4_sensitivity_analyses.R")```

Includes:
- Index reviews only
- Removal of AMSTAR-2 'very low' reviews

## Figures & tables

To reproduce the figures from the paper, use: 

```source("analysis/R/5_forest_plots.R")```

This produces:
– Forest plot of main comparators
– Subgroup forest plot

Outputs are then saved to /results/plots/figs_main

# Scripts and workflows

run_all.R orchestrates the full workflow.

Each script in analysis/R/ is modular.

Re-run individual components by sourcing the corresponding script.

Example:

```source("analysis/R/3_models_subgroups_RVE.R")```

# Data

This folder contains the data used for second-order meta-analysis. 

## data/ma_results.xlsx

Contains extracted results from each included meta-analysis:
- Sensitivity and specificity
- Lower/upper 95% confidence bounds
- Modality, anatomy, validation type
- Comparator group
- Population
- Number of included primary studies
- Meta-analytic method used (RE, bivariate, HSROC, etc.)

## data/forest_plots.xlsx

Contains the final  tables used to generate Forest plots.

No patient-level data are included.

# Output and figures

All results are stored in:

```analysis/results/```

## Model objects (.rds)

These include:
- prepared_data.rds
- main_models.rds
- multivariable_models.rds
- rve_models.rds
- sensitivity_models.rds
- appendix_model_checks.rds

## Tables 

Saved under: ```results/tables/ ```
Include all estimates used in manuscript figures and supplementary tables.

## Figures

Saved under:

```results/plots/figs_main/```

PDF and PNG versions are provided.

# Supplement

Supplementary data cited in the paper.

# Required R packages

Wickham H, Bryan J (2025). _readxl: Read Excel Files_.
  doi:10.32614/CRAN.package.readxl
  <https://doi.org/10.32614/CRAN.package.readxl>, R package version
  1.4.5, <https://CRAN.R-project.org/package=readxl>

Schauberger P, Walker A (2025). _openxlsx: Read, Write and Edit xlsx
  Files_. doi:10.32614/CRAN.package.openxlsx
  <https://doi.org/10.32614/CRAN.package.openxlsx>, R package version
  4.2.8, <https://CRAN.R-project.org/package=openxlsx>.

Wickham H, Averick M, Bryan J, Chang W, McGowan LD, François R,
  Grolemund G, Hayes A, Henry L, Hester J, Kuhn M, Pedersen TL, Miller
  E, Bache SM, Müller K, Ooms J, Robinson D, Seidel DP, Spinu V,
  Takahashi K, Vaughan D, Wilke C, Woo K, Yutani H (2019). “Welcome to
  the tidyverse.” _Journal of Open Source Software_, *4*(43), 1686.
  doi:10.21105/joss.01686 <https://doi.org/10.21105/joss.01686>.

Viechtbauer, W. (2010). Conducting meta-analyses in R with the
  metafor package. Journal of Statistical Software, 36(3), 1-48.
  https://doi.org/10.18637/jss.v036.i03

Balduzzi S, Rücker G, Schwarzer G (2019), How to perform a
  meta-analysis with R: a practical tutorial, Evidence-Based Mental
  Health; 22: 153-160.

Pustejovsky JE (2025). _clubSandwich: Cluster-Robust (Sandwich)
  Variance Estimators with Small-Sample Corrections_.
  doi:10.32614/CRAN.package.clubSandwich
  <https://doi.org/10.32614/CRAN.package.clubSandwich>, R package
  version 0.6.1, <https://CRAN.R-project.org/package=clubSandwich>.

Hester J, Bryan J (2024). _glue: Interpreted String Literals_.
  doi:10.32614/CRAN.package.glue
  <https://doi.org/10.32614/CRAN.package.glue>, R package version
  1.8.0, <https://CRAN.R-project.org/package=glue>.

Fisher Z, Tipton E, Zhipeng H (2023). _robumeta: Robust Variance
  Meta-Regression_. doi:10.32614/CRAN.package.robumeta
  <https://doi.org/10.32614/CRAN.package.robumeta>, R package version
  2.1, <https://CRAN.R-project.org/package=robumeta>.

Dayimu A (2025). _forestploter: Create a Flexible Forest Plot_.
  doi:10.32614/CRAN.package.forestploter
  <https://doi.org/10.32614/CRAN.package.forestploter>, R package
  version 1.1.3, <https://CRAN.R-project.org/package=forestploter>.

  
# How to cite 

If you use code or processed data:

Kuo, R. (2025). aifracturedetection_umbrella: Code and data for 
"Performance of artificial intelligence for fracture detection: 
an overview of reviews and second-order meta-analysis". 
https://github.com/rachelylk/aifracturedetection_umbrella

# Generative AI declaration

Code for second-order meta-analysis and producing Forest plots, was written by RK (Supplement 6). 
For the purposes of this repository, the code in Supplement 6 was refactored and modularised. Generative AI was used to split the full code into modules. 
All outputs have been checked. 

# Contact

Please contact rachel.kuo@ndorms.ox.ac.uk with queries. 

