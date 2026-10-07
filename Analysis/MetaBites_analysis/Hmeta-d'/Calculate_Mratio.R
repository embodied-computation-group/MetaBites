###########################################################################
# MetaBites — meta-d' model fitting
#
# Fits all meta-d' models and saves the fit objects to ../Variables.
# All summaries and inference are in Analysis_main.R (section 3.4).
# Run from the Hmeta-d' folder.
#
#   1. Hierarchical HMeta-d fit per condition (main analysis)
#   2. Non-hierarchical MLE fits per participant x condition
#   3. HMeta-d regression fits: covariate effects on log(Mratio)
#   4. HMeta-d correlation fit: across-condition correlation of Mratio (rho)
###########################################################################

# Clean the environment
rm(list = ls())

## Packages ----------------------------------------------------------------
library(rjags)
library(coda)
library(readxl)
library(dplyr)
library(tidyr)
library(purrr)
library(metaSDT)   # remotes::install_github("craddm/metaSDT")


# functions
source("R/trials2counts.R")
source("R/fit_metad_group.R")

# Load data ---------------------------------------------------------------
# Define the path to the Excel file
data_path <- file.path("..", "Data", "Meta-d_data.xlsx")

# Load the Excel file
metad_data <- read_excel(data_path)
metadata <- metad_data[complete.cases(metad_data),]

# Apply the same trial exclusion as all other analyses: keep only trials that
# are in the trial-level file (mat2excel.m discards trials with RT < 50 ms)
trials_kept <- read_excel(file.path("..", "Data", "MetaBites_triallevel_master.xlsx")) %>%
  mutate(sID = as.numeric(sID), trial = as.numeric(trial)) %>%   # sID is stored as text
  distinct(sID, trial)
metadata <- metadata %>%
  semi_join(trials_kept, by = c("sid" = "sID", "trial" = "trial"))
cat("Trials entering the meta-d' fits:", nrow(metadata), "\n")   # 9472

metadata <- metadata %>%
  mutate(sid  = as.factor(sid), condition = factor(condition))


subjects   <- levels(metadata$sid)
conditions <- levels(metadata$condition)
nSubj      <- length(subjects)
nRatings   <- 5


# Confidence rebinning ----------------------------------------------------
rebin <- function(confidence, k = 5) {
  n <- length(confidence)
  ord <- order(confidence, method = "radix")
  bin <- integer(n)
  edges <- floor(seq(0, n, length.out = k + 1))
  for (i in seq_len(k)) {
    idx <- ord[(edges[i] + 1):edges[i + 1]]
    bin[idx] <- i
  }
  bin
}

metadata <- metadata %>%
  group_by(sid, condition) %>%
  mutate(rebinnedconfidence = rebin(confidence, k = nRatings)) %>%
  ungroup()


# Response counts ---------------------------------------------------------

# Function to process one participant-condition subset
process_subset <- function(subset_df, nRatings = 5) {
  stimID <- subset_df$signal
  response <- subset_df$response
  rating <- subset_df$rebinnedconfidence
  trials2counts(stimID, response, rating, nRatings)
}

# Split metadata by condition and sid
split_data <- metadata %>%
  group_by(condition, sid) %>%
  group_split()

# Apply trials2counts to each subset
results <- map(split_data, ~ process_subset(.x, nRatings = 5))

# Extract keys for naming
keys <- map(split_data, ~ paste(unique(.x$condition), unique(.x$sid), sep = "_"))

# Separate nR_S1 and nR_S2
nR_S1_list <- map(results, 1)
nR_S2_list <- map(results, 2)

# Combine by condition into data frames
combine_by_condition <- function(condition_name, keys, nR_list) {
  idx <- grepl(condition_name, keys)
  df <- do.call(cbind, nR_list[idx])
  colnames(df) <- gsub(paste0(condition_name, "_"), "", keys[idx])
  as.data.frame(df)
}

# Get all unique conditions
conditions <- unique(metadata$condition)

# Create hierarchical lists for all conditions
final_structure <- map(conditions, function(cond) {
  list(
    nR_S1 = combine_by_condition(cond, keys, nR_S1_list),
    nR_S2 = combine_by_condition(cond, keys, nR_S2_list)
  )
})

names(final_structure) <- conditions

# Count matrices per condition (rows = response categories, columns = subjects
# in the order of `subjects`), used by the models in 2-4
cond_levels <- c(Calories = "calories", NRF = "nrf")   # labels -> data codes
counts <- lapply(cond_levels, function(cond) {
  list(nR_S1 = as.matrix(final_structure[[cond]]$nR_S1[, subjects]),
       nR_S2 = as.matrix(final_structure[[cond]]$nR_S2[, subjects]))
})


###########################################################################
# 1. Hierarchical HMeta-d fit per condition --------------------------------
###########################################################################

output_nrf <- fit_metad_group(nR_S1 = list(final_structure[["nrf"]]$nR_S1),
  nR_S2 = list(final_structure[["nrf"]]$nR_S2))
output_cal <- fit_metad_group(nR_S1 = list(final_structure[["calories"]]$nR_S1),
                              nR_S2 = list(final_structure[["calories"]]$nR_S2))

save(output_cal, file = "../Variables/output_cal.RData")
save(output_nrf, file = "../Variables/output_nrf.RData")
save(subjects,   file = "../Variables/subjects.RData")


###########################################################################
# Covariates for the individual-difference models (2 and 3) ---------------
###########################################################################

# Mean trial-level confidence (raw 1-100 VAS) over the trials entering the fits
mean_conf <- metadata %>%
  group_by(sid, condition) %>%
  summarise(mean_confidence = mean(confidence), .groups = "drop") %>%
  mutate(sID = as.numeric(as.character(sid)),
         Condition = names(cond_levels)[match(as.character(condition), cond_levels)]) %>%
  select(sID, Condition, mean_confidence)

# Within-participant SD of the stimulus difference (z-scored within condition)
trials <- read_excel(file.path("..", "Data", "MetaBites_triallevel_master.xlsx"))
stimdiff_var <- trials %>%
  mutate(Condition = recode(as.character(condition), "1" = "Calories", "2" = "NRF"),
         sID = as.numeric(sID)) %>%
  group_by(sID, Condition) %>%
  summarise(stimdiff_sd = sd(stimdiff, na.rm = TRUE), .groups = "drop") %>%
  group_by(Condition) %>%
  mutate(stimdiff_sd_z = as.numeric(scale(stimdiff_sd))) %>%
  ungroup()

covariates <- mean_conf %>% left_join(stimdiff_var, by = c("sID", "Condition"))
stopifnot(!any(is.na(covariates$stimdiff_sd_z)))   # IDs must match across files


###########################################################################
# 2. Non-hierarchical MLE fits per participant x condition -----------------
###########################################################################

fit_mle <- function(nR_S1, nR_S2) {
  # add_constant = TRUE pads every cell by 1/(2*nRatings) to avoid zero counts
  f <- fit_meta_d_MLE(nR_S1, nR_S2, add_constant = TRUE)
  c(dprime = f$da[1], metad = f$meta_da[1], Mratio = f$M_ratio[1])
}

mratio_mle <- map_dfr(names(cond_levels), function(lab) {
  cm  <- counts[[lab]]
  res <- t(sapply(seq_len(nSubj), function(j) fit_mle(cm$nR_S1[, j], cm$nR_S2[, j])))
  data.frame(sID = as.numeric(subjects), Condition = lab, res)
}) %>%
  left_join(covariates, by = c("sID", "Condition"))

save(mratio_mle, file = "../Variables/metad_mle_fits.RData")


###########################################################################
# Helpers for the hierarchical models (3 and 4) ---------------------------
###########################################################################

# Type 1 d' and c, computed as in the HMeta-d wrappers (padded counts)
type1_params <- function(nR_S1, nR_S2) {
  nR  <- nrow(nR_S1) / 2
  adj <- 1 / (2 * nR)
  t(sapply(seq_len(ncol(nR_S1)), function(j) {
    s1  <- nR_S1[, j] + adj
    s2  <- nR_S2[, j] + adj
    HR  <- sum(s2[(nR + 1):(2 * nR)]) / sum(s2)
    FAR <- sum(s1[(nR + 1):(2 * nR)]) / sum(s1)
    c(d1 = qnorm(HR) - qnorm(FAR), c1 = -0.5 * (qnorm(HR) + qnorm(FAR)))
  }))
}

# JAGS runner; per-chain RNG seeds make the MCMC reproducible
run_jags <- function(model_file, data, monitor, n_burn = 1000, n_iter = 10000,
                     n_chains = 3) {
  inits <- lapply(seq_len(n_chains), function(i)
    list(.RNG.name = "base::Mersenne-Twister", .RNG.seed = 122 + i))
  m <- jags.model(file.path("R", model_file), data = data, inits = inits,
                  n.chains = n_chains, quiet = TRUE)
  update(m, n.iter = n_burn)
  coda.samples(m, variable.names = monitor, n.iter = n_iter)
}


###########################################################################
# 3. HMeta-d regression: logMratio_s = mu + beta * cov_s + noise -----------
#    One fit per condition x covariate; covariate z-scored within condition,
#    so beta = change in log(Mratio) per 1 SD of the covariate
###########################################################################

fit_metad_regression <- function(nR_S1, nR_S2, cov) {
  t1 <- type1_params(nR_S1, nR_S2)
  data <- list(d1 = t1[, "d1"], c1 = t1[, "c1"], nsubj = ncol(nR_S1),
               counts = cbind(t(nR_S1), t(nR_S2)),
               cov = as.numeric(scale(cov)),
               nratings = nrow(nR_S1) / 2, Tol = 1e-05)
  run_jags("Bayes_metad_group_regress_nodp.txt", data,
           c("mu_logMratio", "sigma_logMratio", "mu_beta1"))
}

reg_specs <- expand.grid(Condition = names(cond_levels),
                         covariate = c("mean_confidence", "stimdiff_sd"),
                         stringsAsFactors = FALSE)

reg_fits <- pmap(reg_specs, function(Condition, covariate) {
  cov <- covariates %>%
    filter(Condition == !!Condition) %>%
    slice(match(as.numeric(subjects), sID)) %>%     # align to count columns
    pull(!!covariate)
  cat("Fitting hierarchical regression:", Condition, "~", covariate, "\n")
  fit_metad_regression(counts[[Condition]]$nR_S1, counts[[Condition]]$nR_S2, cov)
})

save(reg_specs, reg_fits, file = "../Variables/metad_regression_fits.RData")


###########################################################################
# 4. HMeta-d correlation: across-condition correlation of Mratio (rho) -----
#    Longer chains than the other fits: sigma_logMratio mixes slowly here
###########################################################################

t1_cal <- type1_params(counts$Calories$nR_S1, counts$Calories$nR_S2)
t1_nrf <- type1_params(counts$NRF$nR_S1,      counts$NRF$nR_S2)

corr_data <- list(
  d1 = cbind(t1_cal[, "d1"], t1_nrf[, "d1"]),
  c1 = cbind(t1_cal[, "c1"], t1_nrf[, "c1"]),
  nsubj = nSubj,
  counts1 = cbind(t(counts$Calories$nR_S1), t(counts$Calories$nR_S2)),
  counts2 = cbind(t(counts$NRF$nR_S1),      t(counts$NRF$nR_S2)),
  nratings = nRatings, Tol = 1e-05)

cat("Fitting HMeta-d group correlation model (Calories vs NRF)...\n")
corr_fit <- run_jags("Bayes_metad_group_corr2_R.txt", corr_data,
                     c("mu_logMratio", "sigma_logMratio", "rho"),
                     n_burn = 5000, n_iter = 40000)

save(corr_fit, corr_data, file = "../Variables/metad_corr_fit.RData")
