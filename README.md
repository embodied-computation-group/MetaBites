# MetaBites

**Dissociating accuracy and metacognition in nutritional judgements**

This repository contains the experimental task code, anonymised behavioural data and analysis scripts for the MetaBites study. The MetaBites task is a two-alternative forced-choice (2AFC) paradigm in which participants judge which of two foods has the higher caloric density (calories condition) or the higher Nutrient-Rich Foods (NRF9.3) index (NRF condition), under adaptive difficulty control, and rate their confidence at trial, block and task level.

**Paper**: Hoogervorst, K., Bavato, F., Tyrer, A., & Allen, M. (2026). Dissociating accuracy and metacognition in nutritional judgements. *Cognition*. DOI: *to be added on publication*

**Ethics**: Approved by the institutional Research Ethics Committee, Aarhus University, Denmark (2025-009).

**Contact**: Kelly Hoogervorst (kellyh@cfin.au.dk), Center of Functionally Integrative Neuroscience, Aarhus University. Questions about the data or code can also be raised as an issue on this repository.

---

## Repository structure

```
MetaBites/
├── Analysis/
│   └── MetaBites_analysis/             # R project (MetaBites_analysis.Rproj)
│       ├── Analysis_main.R             # All statistics reported in the paper and supplement
│       ├── Plot_figures.R              # Figures 1-5 and Supplementary Figures S1-S4
│       ├── Data/                       # Processed data (output of the MATLAB export scripts)
│       ├── Variables/                  # Saved intermediate objects and model fits (.RData)
│       ├── Figures/                    # Figure output
│       └── Hmeta-d'/                   # R project (Metabites_mratio.Rproj)
│           ├── Calculate_Mratio.R      # Fits all meta-d' models, saves to ../Variables
│           └── R/                      # HMeta-d functions and JAGS model files
│
└── Task/
    └── Behavioural/                    # MATLAB / Psychtoolbox task and data export
        ├── runMetaBitesTask.m          # Task launcher
        ├── setup_paths.m               # Path configuration used by the launcher
        ├── make_nutrient_list.m        # Builds the stimulus lists from the Full4Health nutrient file
        ├── functions/                  # General MATLAB helper functions
        ├── analysis/
        │   ├── mat2excel.m             # Raw .mat -> processed Excel files (Analysis/.../Data)
        │   ├── mat2metad.m             # Raw .mat -> Meta-d_data.xlsx (input for meta-d' fits)
        │   └── Stimdiff_heatmap.m      # Stimulus difference heatmaps (Supplementary Fig. S1)
        ├── figures/                    # MATLAB figure output
        └── MetaBites_task/
            ├── stimuli/food/           # Full4Health nutrient information (xlsx) and image overview
            └── taskcode/runtask/       # Task code, stimulus lists (list_*_complete.mat)
                ├── Food/               # Food images shown by the task
                └── Data/               # Raw data, one MetaBitesData_<sID>.mat per participant
```

---

## Reproducing the analyses

Run the steps in this order. Steps 1-2 are only needed to regenerate the processed data; the processed data and model fits are already included, so the R scripts (steps 3-5) can be run directly.

| Step | Script | Run from | Output |
|------|--------|----------|--------|
| 1 | `Task/Behavioural/make_nutrient_list.m` (optional) | `Task/Behavioural/` | Stimulus lists `list_cal_complete.mat`, `list_nrf_complete.mat` (already included) |
| 2 | `Task/Behavioural/analysis/mat2excel.m` and `mat2metad.m` | `Task/` | Processed data in `Analysis/MetaBites_analysis/Data/` |
| 3 | `Calculate_Mratio.R` | `Analysis/MetaBites_analysis/Hmeta-d'/` (open `Metabites_mratio.Rproj`) | Meta-d' fits in `Variables/` |
| 4 | `Analysis_main.R` | `Analysis/MetaBites_analysis/` (open `MetaBites_analysis.Rproj`) | Statistics (console) and objects in `Variables/` |
| 5 | `Plot_figures.R` | `Analysis/MetaBites_analysis/` | Figures in `Figures/` |

**Notes**

- The MATLAB scripts use Windows-style paths (`\`) and must be run on Windows, from the folder given in the table (`mat2excel.m` and `mat2metad.m` from `Task/`, not from `Task/Behavioural/analysis/`).
- `Analysis_main.R` (section 3.4) and `Plot_figures.R` (Figure 5) use the meta-d' fits saved by `Calculate_Mratio.R`, so run step 3 before steps 4-5 if you refit the models. MCMC sampling makes refitted values vary slightly between runs.
- Two figure elements are finished outside R:
  - **Figure 1A** (task schematic) was drawn separately and placed in the empty panel A produced by `Plot_figures.R`.
  - **Supplementary Figure S1** (stimulus difference heatmaps) is made in MATLAB with `Stimdiff_heatmap.m`; `Plot_figures.R` only produces the panel layout.
- Confidence for the meta-d' fits is re-binned in `Calculate_Mratio.R` into five equal-count bins per participant and condition; the `binnedconfidence` column in `Meta-d_data.xlsx` is not used.

---

## Participants and exclusions

Data were collected from 38 participants (IDs 3001-3038). Thirty-two are included in all analyses; the included IDs are listed in `mat2excel.m` and `mat2metad.m` (`subject_ids`). Raw task files are provided for all participants with complete task data, including excluded ones. Trials with a reaction time under 50 ms, and trials without a response, are discarded during export (`mat2excel.m`, `mat2metad.m`); `Calculate_Mratio.R` additionally keeps only the trials in `MetaBites_triallevel_master.xlsx`, so all analyses use the same 9,472 trials.

---

## Data files

Processed data in `Analysis/MetaBites_analysis/Data/`:

| File | Description |
|------|-------------|
| `MetaBites_master.xlsx` | One row per participant: accuracy, RT, confidence, task- and block-level global confidence, per-block accuracy and confidence |
| `MetaBites_triallevel_master.xlsx` | One row per trial: response, accuracy, RT, confidence, staircase difference target, reversals |
| `MetaBites_trialratings.xlsx` | One row per trial with the IDs, familiarity and liking ratings of the left and right food |
| `MetaBites_ratings_master.xlsx` | One row per participant x food item: familiarity, liking, nutrient values, selection counts |
| `Meta-d_data.xlsx` | Trial-level stimulus, response and confidence, formatted for the meta-d' fits |
| `stim_data.xlsx` | Food items used (n = 285): image number, name, calories/100 g, NRF9.3/100 g |
| `demographics.csv` | Age, gender and BMI of the 32 included participants |

### Key variables

| Variable | Description |
|----------|-------------|
| `sID` | Participant ID |
| `trial` | Trial number (1-300) |
| `condition` | 1 = Calories, 2 = NRF |
| `response` | 1 = left food chosen, 2 = right food chosen |
| `correct` | 1 = correct, 0 = incorrect |
| `RT` | Choice reaction time (s) |
| `confidence` | Trial-level confidence (VAS, 1-100) |
| `stimdiff` | Staircase difference target recorded by the task (`results.DifferenceTarget`) |
| `item_left`, `item_right` | Image numbers of the foods shown (match `image` in `stim_data.xlsx`) |
| `SB_pre_*`, `SB_post_*` | Task-level global confidence before and after the task (`*` = `cal` or `nrf`) |
| `SB_*_1` … `SB_*_5` | Block-level global confidence after each block |

---

## Requirements

### MATLAB (task and data export)

- MATLAB on Windows with Psychtoolbox-3 (to run the task)
- `mat2excel.m`, `mat2metad.m` and `Stimdiff_heatmap.m` need base MATLAB only

### R (analysis)

- R with the packages below
- [JAGS](https://mcmc-jags.sourceforge.io/) (required by `rjags` for the meta-d' fits)

```r
# Analysis_main.R and Plot_figures.R
install.packages(c("readxl", "dplyr", "tidyr", "purrr", "tibble", "stringr",
                   "ggplot2", "gghalves", "ggsignif", "ggpubr", "patchwork",
                   "lme4", "lmerTest", "ggeffects", "emmeans", "ez", "glmmTMB",
                   "pwr", "coda", "HDInterval", "psych"))

# Calculate_Mratio.R and the HMeta-d functions in Hmeta-d'/R/
install.packages(c("rjags", "tidyverse", "magrittr", "reshape2", "lattice",
                   "broom", "ggmcmc", "remotes"))
remotes::install_github("craddm/metaSDT")
```

The meta-d' functions in `Hmeta-d'/R/` are the R implementation of HMeta-d (Fleming, 2017; R adaptation by A. Mazancieux).

---

## Stimuli

Food images and nutrient information are from the Full4Health Image Collection (Charbonnier et al., 2016; https://osf.io/cx7tp/). The task loads the images from `Task/Behavioural/MetaBites_task/taskcode/runtask/Food/`.

---

## Colour scheme

Used consistently across figures: **Calories** `#D95F02` (orange), **NRF** `#1B9E77` (green).
