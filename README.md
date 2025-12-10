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
- [How to cite](#how-to-cite)
- [Contributing](#contributing)
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
│   └── results/
│       ├── models/
│       ├── tables/
│       └── plots/
│           └── figs_main/
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

Each script in 05_analysis/R/ is modular and documented.

Re-run individual components by sourcing the corresponding script.

Example:

source("05_analysis/R/03_models_subgroups_RVE.R")



