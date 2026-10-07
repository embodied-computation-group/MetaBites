###########################################################################
# Analyse MetaBites Data --------------------------------------------------
#
# Sections follow the manuscript: Methods (2.4-2.5), Results (3.1-3.4),
# Supplementary (S2-S3). meta-d' models are fitted beforehand in
# Hmeta-d'/Calculate_Mratio.R; figures are made in Plot_figures.R.
###########################################################################

# Clean the environment
rm(list = ls())
set.seed(123)  # reproducibility

# Libraries
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(purrr)
library(tibble)
library(stringr)
library(gghalves)
library(ggsignif)
library(ggpubr)
library(patchwork)
library(lme4)
library(lmerTest)
library(ggeffects)
library(emmeans)
library(ez)
library(glmmTMB)
library(pwr)
library(coda)
library(HDInterval)
# load and  structure data ----------------------------
master_path <- file.path("Data", "MetaBites_master.xlsx")
trial_path <- file.path("Data", "MetaBites_triallevel_master.xlsx")
stimratings_path <- file.path("Data", "MetaBites_ratings_master.xlsx")
stim_path <- file.path("Data", "stim_data.xlsx")
ratings_path <- file.path("Data", "MetaBites_trialratings.xlsx")
demo_path <- file.path("Data", "demographics.csv")

master <- readxl::read_excel(master_path)               # task level data
trials <- readxl::read_excel(trial_path)                # trial level data
stimratings <- readxl::read_excel(stimratings_path)     # task level data with ratings
stim_data <- readxl::read_excel(stim_path)              # stimulus information
ratings <- readxl::read_excel(ratings_path)             # trial level data with ratings
demo <- read.csv(demo_path, stringsAsFactors = FALSE)   # demographic data
demo <- demo[, c(1:3)]
colnames(demo)[1] <- "sID"


# Combine master + demo into subj_data
subj_data <- dplyr::inner_join(demo, master, by = 'sID')
# rename SB columns (as in your original)
colnames(subj_data)[16:25] <- c("SB_1_cal","SB_1_nrf", "SB_2_cal","SB_2_nrf",
                                "SB_3_cal","SB_3_nrf", "SB_4_cal","SB_4_nrf", "SB_5_cal","SB_5_nrf")

###########################################################################
# 2.4 Stimuli --------------------------------------------------------------
###########################################################################

descriptives <- stim_data %>%
  select(calories, nrf) %>%
  psych::describe() %>%
  as.data.frame()

descriptives

# Correlation test
# ----------------------------
cor_test <- cor.test(stim_data$calories, stim_data$nrf, method = "pearson")
cor_test

###########################################################################
# 2.5 Data analysis: sensitivity analysis (N = 32) --------------------------
###########################################################################

# Sensitivity: given N, alpha, and desired power, find smallest detectable effect
sens_80 <- pwr.t.test(n = 32, sig.level = 0.05, power = 0.80,
                      type = "paired", alternative = "two.sided")
sens_90 <- pwr.t.test(n = 32, sig.level = 0.05, power = 0.90,
                      type = "paired", alternative = "two.sided")

cat("--- Sensitivity analysis (paired t-test, N = 32, α = .05, two-tailed) ---\n")
cat("Minimum detectable dz at 80% power:", round(sens_80$d, 3), "\n")
cat("Minimum detectable dz at 90% power:", round(sens_90$d, 3), "\n\n")

###########################################################################
# 3.1 Higher confidence in caloric judgements despite lower accuracy -------
###########################################################################

# d' -----------------------------------------------------------------------
# Mutate data
sdt_stats <- trials %>%
  group_by(sID, condition) %>%
  summarise(hits = sum(correct == 1), n_trials = n(), fas = sum(correct == 0), .groups = "drop")

dprime_data <- sdt_stats %>%
  mutate(hit_rate = pmin(pmax(hits / n_trials, 1/(2*n_trials)), 1 - 1/(2*n_trials)),
         fa_rate = pmin(pmax(fas / n_trials, 1/(2*n_trials)), 1 - 1/(2*n_trials)),
         dprime = qnorm(hit_rate) - qnorm(fa_rate), cond_label = ifelse(condition == 1, "Calories", "NRF")) %>%
  select(sID, cond_label, dprime)

# save for plotting
save(dprime_data, file = "Variables/dprime.RData")

dprime_wide <- dprime_data %>% pivot_wider(names_from = cond_label, values_from = dprime)
dprime_wide <- dprime_wide %>%
  mutate(diff = Calories - NRF)

# Remove outliers using IQR method on difference scores
Q1 <- quantile(dprime_wide$diff, 0.25, na.rm = TRUE)
Q3 <- quantile(dprime_wide$diff, 0.75, na.rm = TRUE)
IQR_val <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR_val
upper_bound <- Q3 + 1.5 * IQR_val

outliers <- dprime_wide %>% filter(diff < lower_bound | diff > upper_bound)
cat("Outliers removed (n =", nrow(outliers), "):", outliers$sID, "\n")

dprime_wide <- dprime_wide %>% filter(diff >= lower_bound & diff <= upper_bound)

# Reflect outlier removal back into long-format data
dprime_data <- dprime_data %>% filter(sID %in% dprime_wide$sID)

# Test assumptions
shapiro.test(dprime_wide$diff)
boxplot(dprime_wide$diff, main = "Difference Scores (Calories - NRF)")

# Paired t-test
t_test_dprime <- t.test(dprime_wide$Calories, dprime_wide$NRF, paired = TRUE)
print(t_test_dprime)

# Observed effect size, for comparison with the sensitivity analysis
dz_dprime <- mean(dprime_wide$diff) / sd(dprime_wide$diff)
cat("Observed dz for d′ (Calories vs NRF):", round(abs(dz_dprime), 3), "\n")

# Get descriptives
dprime_descriptives <- dprime_data %>%
  group_by(cond_label) %>%
  summarise(M = mean(dprime), SD = sd(dprime))
print(dprime_descriptives)

# Accuracy per block ------------------------------------------------------
# mutate data
acc_long <- subj_data[, c(1, 36, 37, 40, 41, 44, 45, 48, 49, 52, 53)] %>%
  pivot_longer(cols = starts_with("acc_"), names_to = c("condition", "block"),
               names_pattern = "acc_(.*)_block_(\\d+)",  values_to = "accuracy") %>%
  mutate(block = as.integer(block), condition = recode(condition, "cal" = "Calories", "nrf" = "NRF"),
         accuracy = accuracy * 100,
         accuracy_centered = accuracy - 71)  # center on 71% staircase target

# save for plotting
save(acc_long, file = "Variables/acc_long.RData")

# test for consistency across blocks (unchanged)
model_combined <- glmmTMB(accuracy ~ condition * block + (1|sID), 
                          data = acc_long)
summary(model_combined)

# Condition effect on accuracy. block is not centred, so the conditionNRF
# coefficient above is the difference at block 0; compare the marginal means
# (averaged over blocks, i.e. at block = 3) instead
pairs(emmeans(model_combined, ~ condition), reverse = TRUE)  # NRF - Calories

# Test the slope of block within each condition (unchanged)
test(emtrends(model_combined, ~ condition, var = "block"))

# test deviation from 71% staircase target
model_centered <- glmmTMB(accuracy_centered ~ condition * block + (1|sID), 
                           data = acc_long)

# Test whether each condition's marginal mean differs from 71% (i.e., from 0)
emm_centered <- emmeans(model_centered, ~ condition)
test(emm_centered, null = 0)  # tests if marginal means differ from 0 (= 71%)

# descriptives (unchanged)
acc_overall <- acc_long %>%
  group_by(condition) %>%
  summarise(M = mean(accuracy), SD = sd(accuracy))
print(acc_overall)

acc_by_block <- acc_long %>%
  group_by(condition, block) %>%
  summarise(M = mean(accuracy), SD = sd(accuracy), .groups = "drop")
print(acc_by_block)


# accuracy and reaction time interaction ----------------------------------
# mutate data
rt_long <- subj_data %>%
  select(sID, RT_correct_cal, RT_correct_nrf, RT_incorrect_cal, RT_incorrect_nrf) %>%
  pivot_longer(cols = -sID, names_to = c("Accuracy", "Condition"),
               names_pattern = "RT_(correct|incorrect)_(cal|nrf)", values_to = "RT") %>%
  mutate(Accuracy = str_to_title(Accuracy), Condition = recode(Condition, "cal" = "Calories", "nrf" = "NRF"))

# Make sure sID is a factor
rt_long$sID <- as.factor(rt_long$sID)
rt_long$Condition <- as.factor(rt_long$Condition)
rt_long$Accuracy <- as.factor(rt_long$Accuracy)

# save for plotting
save(rt_long, file = "Variables/rt_long.RData")

# 2x2 repeated measures ANOVA
anova_rt <- ezANOVA(data = rt_long, dv = RT, wid = sID, within = .(Condition, Accuracy), detailed = TRUE, type = 3)
print(anova_rt) # main accuracy effect

# descriptives
rt_long %>%
  group_by(Condition, Accuracy) %>%
  summarise(N = n(), M = mean(RT, na.rm = TRUE), SD = sd(RT, na.rm = TRUE), SE = SD / sqrt(N), 
            Median = median(RT, na.rm = TRUE), Min = min(RT, na.rm = TRUE), Max = max(RT, na.rm = TRUE), .groups = "drop")

# descriptives per accuracy level, collapsed over condition (as reported in 3.1)
rt_long %>%
  group_by(Accuracy) %>%
  summarise(N = n(), M = mean(RT, na.rm = TRUE), SD = sd(RT, na.rm = TRUE), .groups = "drop")


# accuracy and confidence interaction ----------------------------------
# mutate data
conf_long <- subj_data %>%
  select(sID, conf_correct_cal, conf_correct_nrf, conf_incorrect_cal, conf_incorrect_nrf) %>%
  pivot_longer(cols = -sID, names_to = c("Accuracy", "Condition"),
               names_pattern = "conf_(correct|incorrect)_(cal|nrf)", values_to = "Confidence") %>%
  mutate(Accuracy = str_to_title(Accuracy),
         Condition = recode(Condition, "cal" = "Calories", "nrf" = "NRF"))

# Make sure sID is a factor
conf_long$sID <- as.factor(conf_long$sID)
conf_long$Condition <- as.factor(conf_long$Condition)
conf_long$Accuracy <- as.factor(conf_long$Accuracy)

# save for plotting
save(conf_long, file = "Variables/conf_long.RData")

# 2x2 repeated measures ANOVA
anova_conf <- ezANOVA(data = conf_long, dv = Confidence, wid = sID, within = .(Condition, Accuracy), detailed = TRUE, type = 3)
print(anova_conf) # main condition and accuracy effect

# descriptives
conf_long %>%
  group_by(Condition, Accuracy) %>%
  summarise(N = n(), M = mean(Confidence, na.rm = TRUE), SD = sd(Confidence, na.rm = TRUE), SE = SD / sqrt(N), 
            Median = median(Confidence, na.rm = TRUE), Min = min(Confidence, na.rm = TRUE), Max = max(Confidence, na.rm = TRUE), .groups = "drop")

# descriptives per accuracy level, collapsed over condition (as reported in 3.1)
conf_long %>%
  group_by(Accuracy) %>%
  summarise(N = n(), M = mean(Confidence, na.rm = TRUE), SD = sd(Confidence, na.rm = TRUE), .groups = "drop")

conf_long %>%
  group_by(Condition) %>%
  summarise(N = n(), M = mean(Confidence, na.rm = TRUE), SD = sd(Confidence, na.rm = TRUE), SE = SD / sqrt(N), 
            Median = median(Confidence, na.rm = TRUE), Min = min(Confidence, na.rm = TRUE), Max = max(Confidence, na.rm = TRUE), .groups = "drop")


###########################################################################
# 3.2 Familiarity and liking are associated with nutritional judgements ----
###########################################################################

# Correlation between familiarity and liking ------------------------------
# Perform correlation test between liking and familiarity
cor_test_result <- cor.test(stimratings$familiarity, stimratings$liking, method = "pearson")
print(cor_test_result)

# Item selection rates: Calories vs NRF (R1 Comment 2) --------------------
# For each item: proportion of times chosen as "higher" in each condition
# Uses the ratings trial-level file which has item_left, item_right, response, condition

item_selection <- ratings %>%
  mutate(Condition = recode(as.character(condition), "1" = "Calories", "2" = "NRF")) %>%
  pivot_longer(cols = c(item_left, item_right),
               names_to = "side",
               values_to = "item_id") %>%
  mutate(
    # Was this item the chosen one?
    chosen = case_when(
      side == "item_left"  & response == 1 ~ 1,
      side == "item_right" & response == 2 ~ 1,
      TRUE ~ 0
    )
  ) %>%
  group_by(item_id, Condition) %>%
  summarise(
    n_presented = n(),
    n_chosen    = sum(chosen),
    prop_chosen = n_chosen / n_presented,
    .groups = "drop"
  )

# Pivot wide and correlate
item_selection_wide <- item_selection %>%
  pivot_wider(names_from = Condition,
              values_from = c(prop_chosen, n_presented, n_chosen)) %>%
  filter(!is.na(prop_chosen_Calories) & !is.na(prop_chosen_NRF))

cor_item_selection <- cor.test(item_selection_wide$prop_chosen_Calories,
                               item_selection_wide$prop_chosen_NRF,
                               method = "pearson")
print(cor_item_selection)

save(item_selection_wide, cor_item_selection, file = "Variables/item_selection.RData")

# Rating balance across conditions ----------------------------------------

# Average liking and familiarity
ratings <- ratings %>%
  mutate(avg_liking = (liking_left + liking_right) / 2,
         avg_familiarity = (familiarity_left + familiarity_right) / 2,
         Condition = factor(condition, levels = c(1, 2), labels = c("Calories", "NRF")))

# Test for rating differences between conditions
ratings_by_subject <- ratings %>%
  group_by(sID, Condition) %>%
  summarise(
    mean_liking = mean(avg_liking, na.rm = TRUE),
    mean_familiarity = mean(avg_familiarity, na.rm = TRUE),
    .groups = "drop"
  )

# Paired t-tests (each participant contributes to both conditions)
ratings_by_subject_wide <- ratings_by_subject %>%
  pivot_wider(names_from = Condition, values_from = c(mean_liking, mean_familiarity))

t_test_liking <- t.test(ratings_by_subject_wide$mean_liking_Calories,
                        ratings_by_subject_wide$mean_liking_NRF, paired = TRUE)
t_test_familiarity <- t.test(ratings_by_subject_wide$mean_familiarity_Calories,
                             ratings_by_subject_wide$mean_familiarity_NRF, paired = TRUE)

print(t_test_liking)
print(t_test_familiarity)


# Reshape data to long format for plotting
ratings_long <- ratings_by_subject %>%
  pivot_longer(
    cols = c(mean_liking, mean_familiarity),
    names_to = "measure",
    values_to = "rating",
    names_prefix = "mean_"
  ) %>%
  mutate(measure = str_to_title(measure))

# save for plotting
save(ratings_long, file = "Variables/ratings_long.RData")

# Summary statistics
summary_stats <- ratings_long %>%
  group_by(Condition, measure) %>%
  summarise(
    mean_rating = mean(rating),
    se = sd(rating) / sqrt(n()),
    ci_lower = mean_rating - qt(0.975, n() - 1) * se,
    ci_upper = mean_rating + qt(0.975, n() - 1) * se,
    .groups = "drop"
  )

# save for plotting
save(summary_stats, file = "Variables/summary_stats.RData")

# Print summary statistics
print(summary_stats)


# Effect on choice --------------------------------------------------------

ratings <- ratings %>%
  mutate(
    chose_left = if_else(response == 1, 1, 0),
    # Create difference scores
    liking_diff = liking_left - liking_right,
    familiarity_diff = familiarity_left - familiarity_right,
    
    # Recode: did they choose the item with higher liking?
    chose_higher_liking = case_when(
      liking_diff > 0 & chose_left == 1 ~ 1,
      liking_diff < 0 & chose_left == 0 ~ 1,
      liking_diff == 0 ~ NA_real_,
      TRUE ~ 0
    ),
    
    # Recode: did they choose the item with higher familiarity?
    chose_higher_familiarity = case_when(
      familiarity_diff > 0 & chose_left == 1 ~ 1,
      familiarity_diff < 0 & chose_left == 0 ~ 1,
      familiarity_diff == 0 ~ NA_real_,
      TRUE ~ 0
    )
  )

# Use absolute differences as predictors since direction is now in the DV
ratings <- ratings %>%
  mutate(
    abs_liking_diff = abs(liking_diff),
    abs_familiarity_diff = abs(familiarity_diff)
  )

# Combined model: signed predictors, symmetric DV
# Coefficient signs directly test whether the higher-rated item is chosen
model_combined <- glmer(
  chose_left ~ liking_diff * Condition + 
               familiarity_diff * Condition +
               (1 | sID) + (1 | item_left) + (1 | item_right),
  data = ratings,
  family = binomial(link = "logit"),
  control = glmerControl(optimizer = "bobyqa")
)

summary(model_combined)

# Simple slopes per condition (log-odds): the main-effect coefficients above
# are the Calories slopes; these give the NRF slopes and their tests
test(emtrends(model_combined, ~ Condition, var = "familiarity_diff"))
test(emtrends(model_combined, ~ Condition, var = "liking_diff"))

# Prediction data for liking (holding familiarity_diff at 0)
pred_data_combined <- expand.grid(
  liking_diff      = seq(0, max(abs(ratings$liking_diff), na.rm = TRUE), 
                         length.out = 100),
  familiarity_diff = 0,
  Condition        = c("Calories", "NRF")
)
pred_data_combined$prob_chose_higher_liking <- predict(
  model_combined,
  newdata = pred_data_combined,
  type = "response",
  re.form = NA
)

# Prediction data for familiarity (holding liking_diff at 0)
pred_data_fam_combined <- expand.grid(
  familiarity_diff = seq(0, max(abs(ratings$familiarity_diff), na.rm = TRUE), 
                         length.out = 100),
  liking_diff      = 0,
  Condition        = c("Calories", "NRF")
)
pred_data_fam_combined$prob_chose_higher_fam <- predict(
  model_combined,
  newdata = pred_data_fam_combined,
  type = "response",
  re.form = NA
)

# Rename columns so downstream plotting code still works
pred_data_combined     <- pred_data_combined     %>% 
  dplyr::rename(abs_liking_diff = liking_diff)
pred_data_fam_combined <- pred_data_fam_combined %>% 
  dplyr::rename(abs_familiarity_diff = familiarity_diff)

# save for plotting
save(pred_data_combined, file = "Variables/pred_data_combined.RData")
save(pred_data_fam_combined, file = "Variables/pred_data_fam_combined.RData")


# Empirical proportions
empirical_liking <- ratings %>%
  filter(!is.na(chose_higher_liking)) %>%
  mutate(liking_bin = cut(abs_liking_diff, breaks = 10)) %>%
  group_by(liking_bin, Condition) %>%
  summarise(
    prob_chose_higher = mean(chose_higher_liking, na.rm = TRUE),
    abs_liking_diff_mean = mean(abs_liking_diff, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  filter(n >= 5)

empirical_familiarity <- ratings %>%
  filter(!is.na(chose_higher_familiarity)) %>%
  mutate(fam_bin = cut(abs_familiarity_diff, breaks = 10)) %>%
  group_by(fam_bin, Condition) %>%
  summarise(
    prob_chose_higher = mean(chose_higher_familiarity, na.rm = TRUE),
    abs_familiarity_diff_mean = mean(abs_familiarity_diff, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  filter(n >= 5)

# save for plotting
save(empirical_liking, file = "Variables/empirical_liking.RData")
save(empirical_familiarity, file = "Variables/empirical_familiarity.RData")

# Familiarity and liking as predictors of confidence (R1 Comment 3) -------
# Does familiarity difference between items predict trial-level confidence,
# moderated by condition?
# Build dataset
conf_familiarity <- ratings %>%
  mutate(
    abs_familiarity_diff = abs(familiarity_left - familiarity_right),
    abs_liking_diff      = abs(liking_left - liking_right)
  ) %>%
  select(sID, Condition, item_left, item_right,
         confidence, abs_familiarity_diff, abs_liking_diff, stimdiff)

conf_familiarity <- conf_familiarity %>%
  mutate(abs_stimdiff = abs(stimdiff))   # trial-level stimulus difference

# Rescale confidence to [0,1] for ordered beta regression
conf_familiarity <- conf_familiarity %>%
  mutate(conf01 = (confidence - 1) / 99)   # 1-100 VAS → [0,1]

# Fit ordered beta regression to appropriately handle bounded confidence scale
model_fam_conf_ctrl <- glmmTMB(
  conf01 ~ abs_familiarity_diff * Condition + 
    abs_liking_diff * Condition +
    abs_stimdiff +                       # trial difficulty covariate
    (1 | sID) + (1 | item_left) + (1 | item_right),
  data   = conf_familiarity,
  family = ordbeta(link = "logit")
)

summary(model_fam_conf_ctrl)

# Convergence checks
cat("Converged:", model_fam_conf_ctrl$fit$convergence == 0, "\n")
cat("Hessian OK:", model_fam_conf_ctrl$sdr$pdHess, "\n")

# Also check whether abs_stimdiff itself correlates with the rating diffs
conf_familiarity %>%
  group_by(Condition) %>%
  summarise(
    r_stim_fam  = cor(abs_stimdiff, abs_familiarity_diff, use = "complete.obs"),
    r_stim_like = cor(abs_stimdiff, abs_liking_diff, use = "complete.obs"),
    .groups = "drop"
  )

save(model_fam_conf_ctrl, file = "Variables/fam_conf_ctrl.RData")

# Descriptives: mean confidence by familiarity difference bin and condition
fam_conf_descriptives <- conf_familiarity %>%
  group_by(Condition) %>%
  summarise(
    r_fam  = cor(abs_familiarity_diff, confidence, use = "complete.obs"),
    p_fam  = cor.test(abs_familiarity_diff, confidence)$p.value,
    r_like = cor(abs_liking_diff, confidence, use = "complete.obs"),
    p_like = cor.test(abs_liking_diff, confidence)$p.value,
    .groups = "drop"
  )
print(fam_conf_descriptives)


# --- Prediction data for plotting (Figure 3, panels E and F) --------------
# Population-averaged model predictions, comparable to the observed binned
# means: set the focal predictor to each grid value on every trial, predict
# with that trial's participant and item effects, and average per condition.
# (Predictions with random effects set to zero describe a "typical"
# participant and item, which lies below the average on the response scale.)
avg_pred_conf <- function(var, n_grid = 31) {
  grid <- seq(0, max(conf_familiarity[[var]], na.rm = TRUE), length.out = n_grid)
  newdata <- map_dfr(grid, function(x) {
    conf_familiarity %>% mutate(!!var := x, grid_value = x)
  })
  newdata$pred <- predict(model_fam_conf_ctrl, newdata = newdata,
                          type = "response", allow.new.levels = TRUE)
  newdata %>%
    group_by(grid_value, Condition) %>%
    summarise(pred_confidence = mean(pred) * 99 + 1, .groups = "drop") %>%   # back-transform to 1-100 scale
    rename(!!var := grid_value)
}

pred_fam_conf  <- avg_pred_conf("abs_familiarity_diff")
pred_like_conf <- avg_pred_conf("abs_liking_diff")

# Binned empirical means with SEs for the confidence panels
fam_conf_binned <- conf_familiarity %>%
  mutate(fam_bin = cut(abs_familiarity_diff, breaks = 4)) %>%
  group_by(fam_bin, Condition) %>%
  summarise(mean_conf = mean(confidence, na.rm = TRUE),
            se_conf   = sd(confidence, na.rm = TRUE) / sqrt(n()),
            mid       = mean(abs_familiarity_diff, na.rm = TRUE),
            .groups   = "drop")

like_conf_binned <- conf_familiarity %>%
  mutate(like_bin = cut(abs_liking_diff, breaks = 4)) %>%
  group_by(like_bin, Condition) %>%
  summarise(mean_conf = mean(confidence, na.rm = TRUE),
            se_conf   = sd(confidence, na.rm = TRUE) / sqrt(n()),
            mid       = mean(abs_liking_diff, na.rm = TRUE),
            .groups   = "drop")

# Save for plotting
save(conf_familiarity, pred_fam_conf, pred_like_conf,
     fam_conf_binned, like_conf_binned,
     file = "Variables/fam_conf_plotdata.RData")

###########################################################################
# 3.3 Asymmetric confidence updating across conditions ---------------------
###########################################################################

# Global updating ---------------------------------------------------------
# mutate data
sb_long <- subj_data %>%
  select(sID, SB_pre_cal, SB_pre_nrf, SB_post_cal, SB_post_nrf) %>%
  pivot_longer(cols = -sID, names_to = c("Time", "Condition"),
               names_pattern = "SB_(pre|post)_(cal|nrf)", values_to = "SB") %>%
  mutate(Time = factor(Time, levels = c("pre", "post"), labels = c("Pre", "Post")), Condition = recode(Condition, "cal" = "Calories", "nrf" = "NRF"))

# Statistical test
sb_long$Time <- factor(sb_long$Time)
sb_long$Condition <- factor(sb_long$Condition)
sb_long$sID <- factor(sb_long$sID)

# save for plotting
save(sb_long, file = "Variables/sb_long.RData")

anova_time <- ezANOVA(data = sb_long, dv = SB, wid = sID, within = .(Time, Condition), detailed = TRUE)
print(anova_time) # main time effect and time condition interaction

# Descriptives for pre-post global confidence
sb_descriptives <- sb_long %>%
  group_by(Condition, Time) %>%
  summarise(M = mean(SB), SD = sd(SB), .groups = "drop")
print(sb_descriptives)

# Pre vs post collapsed over condition (main effect of Time, as reported in 3.3)
sb_long %>%
  group_by(Time) %>%
  summarise(M = mean(SB), SD = sd(SB), .groups = "drop")

# Follow-up of the Time x Condition interaction: pre vs post within each
# condition (paired t-tests, Holm-corrected across the two conditions)
sb_posthoc <- sb_long %>%
  select(sID, Condition, Time, SB) %>%
  pivot_wider(names_from = Time, values_from = SB) %>%
  group_by(Condition) %>%
  summarise(M_diff = mean(Post - Pre),
            t      = t.test(Post, Pre, paired = TRUE)$statistic,
            df     = t.test(Post, Pre, paired = TRUE)$parameter,
            p      = t.test(Post, Pre, paired = TRUE)$p.value,
            dz     = mean(Post - Pre) / sd(Post - Pre),
            .groups = "drop") %>%
  mutate(p_holm = p.adjust(p, method = "holm"))
print(sb_posthoc)

# Global over time --------------------------------------------------------
# Global confidence across the task: pre-task, after each block, post-task
# (not reported in the manuscript, which reports the pre-post ANOVA above)
global_time_long <- subj_data %>%
  select(sID, matches("^SB_(pre|post|\\d)_(cal|nrf)$")) %>%
  pivot_longer(cols = -sID, names_to = c("Time", "Condition"),
               names_pattern = "SB_(pre|post|\\d)_(cal|nrf)", values_to = "Confidence") %>%
  mutate(Time = case_when(Time == "pre"  ~ "Pre",
                          Time == "post" ~ "Post",
                          TRUE           ~ paste0("Block", Time)),
         Time = factor(Time, levels = c("Pre", paste0("Block", 1:5), "Post")),
         Condition = factor(recode(Condition, "cal" = "Calories", "nrf" = "NRF")),
         sID = factor(sID))

# Repeated measures ANOVA; sphericity is violated, so use the
# Greenhouse-Geisser corrected p-values
anova_global_time <- ezANOVA(data = global_time_long, dv = Confidence, wid = sID,
                             within = .(Time, Condition), detailed = TRUE)
print(anova_global_time)

# Descriptive statistics
global_time_descriptives <- global_time_long %>%
  group_by(Condition, Time) %>%
  summarise(M = mean(Confidence), SD = sd(Confidence), .groups = "drop")
print(global_time_descriptives)


# Global local correlation ------------------------------------------------
sb_data <- subj_data %>%
  pivot_longer(cols = matches("^SB_\\d+_(cal|nrf)$"), names_to = c("block", "Condition"), names_pattern = "SB_(\\d+)_(cal|nrf)", values_to = "SB_value") %>%
  mutate(block = as.integer(block), Condition = recode(Condition, "cal" = "Calories", "nrf" = "NRF")) %>%
  select(sID, block, Condition, SB_value)

conf_data <- subj_data %>%
  pivot_longer(cols = matches("^conf_(cal|nrf)_block_\\d+$"), names_to = c("Condition", "block"), names_pattern = "conf_(cal|nrf)_block_(\\d+)", values_to = "conf_value") %>%
  mutate(block = as.integer(block), Condition = recode(Condition, "cal" = "Calories", "nrf" = "NRF")) %>%
  select(sID, block, Condition, conf_value)

merged_data <- left_join(sb_data, conf_data, by = c("sID", "block", "Condition"))

# Correlation test
cor_cal <- cor.test(merged_data$conf_value[merged_data$Condition == "Calories"], 
                    merged_data$SB_value[merged_data$Condition == "Calories"])
cor_nrf <- cor.test(merged_data$conf_value[merged_data$Condition == "NRF"], 
                    merged_data$SB_value[merged_data$Condition == "NRF"])
print(cor_cal)  # r(df), p and 95% CI as reported in 3.3
print(cor_nrf)

# descriptives
merged_data %>%
  group_by(Condition) %>%
  summarise(correlation = cor(conf_value, SB_value, use = "complete.obs"),
            p_value = cor.test(conf_value, SB_value)$p.value)

# save for plotting
save(merged_data, file = "Variables/merged_data.RData")


# --- Local confidence trial-level data -----------------------------------
local_conf <- trials %>%
  mutate(trial = as.integer(trial),
         Condition = recode(condition, "1" = "Calories", "2" = "NRF"),
         block = ceiling(trial / 30)   # Assign trials to blocks of 30
  )

# --- Compute recency windows ---------------------------------------------
recency_data <- local_conf %>%
  group_by(sID, Condition, block) %>%
  summarise(
    mean_first5 = mean(head(confidence, 5), na.rm = TRUE),
    mean_all = mean(confidence, na.rm = TRUE),
    mean_last5  = mean(tail(confidence, 5), na.rm = TRUE),
    .groups = "drop"
  )

recency_data$sID <- as.numeric(recency_data$sID)

global_conf <- sb_data %>%
  rename(global_conf = SB_value)


recency_data_fixed <- recency_data %>%
  group_by(sID, Condition) %>%
  arrange(block, .by_group = TRUE) %>%
  mutate(block = row_number()) %>%
  ungroup()

recency_merged <- left_join(global_conf, recency_data_fixed,
                            by = c("sID", "Condition", "block"))

# --- Correlations per condition and recency window -----------------------
recency_corr <- recency_merged %>%
  group_by(Condition) %>%
  summarise(
    cor_first5  = cor(global_conf, mean_first5,  use = "complete.obs"),
    cor_all = cor(global_conf, mean_all, use = "complete.obs"),
    cor_last5  = cor(global_conf, mean_last5,  use = "complete.obs"),
    .groups = "drop"
  )

print(recency_corr)



# --- Mixed model with recency predictors ---------------------------------
model_recency <- lmer(
  global_conf ~ mean_first5 + mean_all + mean_last5 +
    Condition + (1 | sID),
  data = recency_merged
)

summary(model_recency)

# Does Condition moderate the window effects? Add window x Condition
# interactions and compare with a likelihood-ratio test (ML fits)
model_recency_int <- lmer(
  global_conf ~ (mean_first5 + mean_all + mean_last5) * Condition + (1 | sID),
  data = recency_merged
)
summary(model_recency_int)
anova(model_recency, model_recency_int)   # refits both with ML


# --- Cluster bootstrap of the recency correlations -------------------------
# Each resample draws participants with replacement (keeping all of their
# blocks in both conditions) and recomputes all six correlations on that same
# draw, so between-condition and between-window differences stay paired.
recency_windows <- c("All Trials"     = "mean_all",
                     "First 5 Trials" = "mean_first5",
                     "Last 5 Trials"  = "mean_last5")
n_boot <- 2000

# Correlation of block-level global confidence with each local window,
# per condition
cor_by_window <- function(df) {
  grid <- expand.grid(Window = names(recency_windows),
                      Condition = c("Calories", "NRF"),
                      stringsAsFactors = FALSE)
  grid$r <- mapply(function(w, cond) {
    d <- df[df$Condition == cond, ]
    cor(d$global_conf, d[[recency_windows[[w]]]], use = "complete.obs")
  }, grid$Window, grid$Condition)
  grid
}

# Two-sided bootstrap p-value: centre the bootstrap distribution on 0 (null)
# and count draws at least as extreme as the observed statistic. The +1 keeps
# p above zero (minimum 1 / (n_boot + 1)).
boot_p <- function(boot_stat, obs) {
  (sum(abs(boot_stat - mean(boot_stat)) >= abs(obs)) + 1) / (length(boot_stat) + 1)
}

r_observed <- cor_by_window(recency_merged)

by_participant <- split(recency_merged, recency_merged$sID)
boot_samples <- map_dfr(seq_len(n_boot), function(b) {
  ids <- sample(names(by_participant), replace = TRUE)
  cor_by_window(bind_rows(by_participant[ids])) %>% mutate(boot = b)
}) %>%
  rename(r_boot = r) %>%
  left_join(rename(r_observed, r_obs = r), by = c("Window", "Condition")) %>%
  mutate(Window = factor(Window, levels = names(recency_windows)))

# --- Correlations against zero (Holm across all 6 tests) -------------------
boot_pvals <- boot_samples %>%
  group_by(Condition, Window) %>%
  summarise(r_obs  = first(r_obs),
            p_boot = boot_p(r_boot, r_obs),
            .groups = "drop") %>%
  mutate(p_holm = p.adjust(p_boot, method = "holm"))

print(boot_pvals)

# --- Between-condition comparisons per window ------------------------------
paired_cond <- boot_samples %>%
  select(boot, Condition, Window, r_boot) %>%
  pivot_wider(names_from = Condition, values_from = r_boot)

between_condition_comparisons <- r_observed %>%
  pivot_wider(names_from = Condition, values_from = r) %>%
  rename(r_obs_cal = Calories, r_obs_nrf = NRF) %>%
  mutate(diff_obs = r_obs_cal - r_obs_nrf,
         p_boot   = map2_dbl(Window, diff_obs, function(w, d) {
           x <- paired_cond[paired_cond$Window == w, ]
           boot_p(x$Calories - x$NRF, d)
         }),
         p_holm   = p.adjust(p_boot, method = "holm"))

print(between_condition_comparisons)

# --- Window comparisons within each condition (Holm across all 6) ----------
window_pairs <- list(c("All Trials", "Last 5 Trials"),
                     c("All Trials", "First 5 Trials"),
                     c("First 5 Trials", "Last 5 Trials"))

paired_win <- boot_samples %>%
  select(boot, Condition, Window, r_boot) %>%
  pivot_wider(names_from = Window, values_from = r_boot)
obs_win <- r_observed %>%
  pivot_wider(names_from = Window, values_from = r)

window_comparisons <- map_dfr(c("Calories", "NRF"), function(cond) {
  b <- paired_win[paired_win$Condition == cond, ]
  o <- obs_win[obs_win$Condition == cond, ]
  map_dfr(window_pairs, function(p) {
    diff_obs <- o[[p[1]]] - o[[p[2]]]
    tibble(Condition  = cond,
           comparison = paste(p[1], "vs", p[2]),
           diff_obs   = diff_obs,
           p_boot     = boot_p(b[[p[1]]] - b[[p[2]]], diff_obs))
  })
}) %>%
  mutate(p_holm = p.adjust(p_boot, method = "holm"))

print(window_comparisons)

# save for plotting
save(boot_samples, file = "Variables/boot_samples.RData")

###########################################################################
# 3.4 Metacognitive efficiency across conditions --------------------------
###########################################################################
# All meta-d' models are fitted in Hmeta-d'/Calculate_Mratio.R (run first);
# this section summarises the saved fits.

# Group-level Mratio per condition ----------------------------------------
load("Variables/output_cal.RData")
load("Variables/output_nrf.RData")

# Posterior mean, 95% HDI and R-hat for every monitored parameter
summarise_fit <- function(fit) {
  draws <- as.matrix(fit)
  hdi_p <- HPDinterval(as.mcmc(draws), prob = 0.95)
  data.frame(name  = colnames(draws),
             mean  = colMeans(draws),
             lower = hdi_p[, "lower"],
             upper = hdi_p[, "upper"],
             Rhat  = gelman.diag(fit, multivariate = FALSE)$psrf[, 1],
             row.names = NULL)
}

Fit_cal <- summarise_fit(output_cal)
Fit_nrf <- summarise_fit(output_nrf)

# Convergence: all R-hat < 1.1
cat("Max R-hat: Calories =", round(max(Fit_cal$Rhat), 3),
    "| NRF =", round(max(Fit_nrf$Rhat), 3), "\n")

# Posterior draws of group-level Mratio
mu_cal_vec <- as.matrix(output_cal)[, "mu_logMratio"]
mu_nrf_vec <- as.matrix(output_nrf)[, "mu_logMratio"]

# Ensure same length
n_draws    <- min(length(mu_cal_vec), length(mu_nrf_vec))
mu_cal_vec <- mu_cal_vec[1:n_draws]
mu_nrf_vec <- mu_nrf_vec[1:n_draws]

M_cal <- exp(mu_cal_vec)
M_nrf <- exp(mu_nrf_vec)

mratio_post <- data.frame(
  Mratio    = c(M_cal, M_nrf),
  Condition = factor(c(rep("Calories", length(M_cal)), rep("NRF", length(M_nrf))),
                     levels = c("Calories", "NRF"))
)

# Group-level Mratio: posterior mean and 95% HDI
mratio_post %>%
  group_by(Condition) %>%
  summarise(mean  = mean(Mratio),
            lower = hdi(Mratio, credMass = 0.95)["lower"],
            upper = hdi(Mratio, credMass = 0.95)["upper"], .groups = "drop") %>%
  print()

# Posterior difference (Calories - NRF) ------------------------------------
delta_logM   <- mu_cal_vec - mu_nrf_vec
mean_diff    <- mean(delta_logM)
hdi_diff     <- hdi(delta_logM, credMass = 0.95)
p_cal_gt_nrf <- mean(delta_logM > 0)
delta_df     <- data.frame(delta = delta_logM)

# On the Mratio scale (Calories / NRF)
delta_ratio     <- exp(delta_logM)
HDI_delta_ratio <- quantile(delta_ratio, c(.025, .975))

cat("--- Posterior Difference (Calories - NRF, log scale) ---\n")
cat("Mean difference:          ", round(mean_diff, 3), "\n")
cat("95% HDI:                  [", round(hdi_diff[1], 3), ",", round(hdi_diff[2], 3), "]\n")
cat("P(Calories > NRF):        ", round(p_cal_gt_nrf, 3), "\n\n")

cat("--- Posterior Difference (Calories / NRF, Mratio scale) ---\n")
cat("Mean ratio:               ", round(mean(delta_ratio), 3), "\n")
cat("95% CI [equal-tailed]:    [", round(HDI_delta_ratio[1], 3), ",", round(HDI_delta_ratio[2], 3), "]\n")

# Savage-Dickey Bayes factor for the difference
# Prior: each condition is fitted separately with mu_logMratio ~ Normal(0, 1)
# (HMeta-d default), so the implied prior on their difference is Normal(0, sqrt(2))
prior_density_at_0     <- dnorm(0, mean = 0, sd = sqrt(2))
posterior_density      <- density(delta_logM, n = 512)
posterior_density_at_0 <- approx(posterior_density$x, posterior_density$y, xout = 0)$y

BF10 <- prior_density_at_0 / posterior_density_at_0   # evidence for a difference
BF01 <- 1 / BF10                                       # evidence for the null

cat("Savage-Dickey BF10 (calories ≠ NRF):", round(BF10, 3), "\n")
cat("Savage-Dickey BF01 (null):", round(BF01, 3), "\n")

# save for plotting
save(delta_df, hdi_diff, mean_diff, p_cal_gt_nrf, file = "Variables/mratio_diff.RData")
save(mratio_post, file = "Variables/mratio_post.RData")


# Individual differences in Mratio -----------------------------------------
# Individual Mratios from the hierarchical fit are shrunk toward the group mean
# and are not used for individual-difference analyses. Instead, covariate
# effects are estimated (i) inside the hierarchical model (primary) and
# (ii) on non-hierarchical MLE fits (robustness check).
# Covariates: mean trial-level confidence, and within-participant SD of the
# stimulus difference (z-scored within condition).

# Posterior summary of one parameter
summarise_param <- function(samples, par) {
  draws <- as.matrix(samples)[, par]
  hdi_p <- HPDinterval(as.mcmc(draws), prob = 0.95)
  data.frame(parameter = par, mean = mean(draws),
             hdi_low = hdi_p[1], hdi_high = hdi_p[2],
             p_gt_0 = mean(draws > 0),
             Rhat = gelman.diag(samples[, par], autoburnin = FALSE)$psrf[1, 1],
             ESS  = unname(effectiveSize(samples[, par])))
}

# Savage-Dickey BF01 for a parameter with a N(0, 1) prior
bf01_sd <- function(samples, par) {
  dens <- density(as.matrix(samples)[, par])
  approx(dens$x, dens$y, xout = 0)$y / dnorm(0, 0, 1)
}

# (i) Hierarchical regression: covariate effect on log(Mratio) -------------
# beta = change in log(Mratio) per 1 SD of the covariate
load("Variables/metad_regression_fits.RData")   # reg_specs, reg_fits

reg_results <- bind_rows(lapply(seq_along(reg_fits), function(i) {
  cbind(reg_specs[i, ],
        summarise_param(reg_fits[[i]], "mu_beta1"),
        BF01 = bf01_sd(reg_fits[[i]], "mu_beta1"))
}))
print(reg_results, digits = 3)

# (ii) Non-hierarchical MLE Mratio ------------------------------------------
load("Variables/metad_mle_fits.RData")          # mratio_mle

mratio_mle %>%
  group_by(Condition) %>%
  summarise(mean = mean(Mratio), median = median(Mratio), sd = sd(Mratio),
            n_nonpositive = sum(Mratio <= 0), .groups = "drop") %>%
  print()

# Mratio x mean confidence (Spearman alongside Pearson for robustness)
cor_conf_mle <- mratio_mle %>%
  group_by(Condition) %>%
  summarise(
    r_pearson = cor(Mratio, mean_confidence),
    p_pearson = cor.test(Mratio, mean_confidence)$p.value,
    rho_spear = cor(Mratio, mean_confidence, method = "spearman"),
    p_spear   = cor.test(Mratio, mean_confidence, method = "spearman", exact = FALSE)$p.value,
    n = n(), .groups = "drop")
print(cor_conf_mle)

# Mratio x stimulus-difference SD
cor_stimvar_mle <- mratio_mle %>%
  group_by(Condition) %>%
  summarise(
    r_pearson = cor(Mratio, stimdiff_sd_z),
    p_pearson = cor.test(Mratio, stimdiff_sd_z)$p.value,
    rho_spear = cor(Mratio, stimdiff_sd_z, method = "spearman"),
    p_spear   = cor.test(Mratio, stimdiff_sd_z, method = "spearman", exact = FALSE)$p.value,
    n = n(), .groups = "drop")
print(cor_stimvar_mle)

model_stimvar_mle <- lmer(Mratio ~ Condition * stimdiff_sd_z + (1 | sID),
                          data = mratio_mle)
summary(model_stimvar_mle)

# Model predictions for plotting
pred_stimvar_mle <- ggpredict(model_stimvar_mle, terms = c("stimdiff_sd_z", "Condition"))

# save for plotting
save(mratio_mle, cor_conf_mle, cor_stimvar_mle, model_stimvar_mle, pred_stimvar_mle,
     file = "Variables/mratio_mle_results.RData")

# Across-condition correlation of Mratio (R1 Comment 1.5) ------------------
load("Variables/metad_corr_fit.RData")          # corr_fit, corr_data

print(gelman.diag(corr_fit, autoburnin = FALSE, multivariate = FALSE))
rho_result <- summarise_param(corr_fit, "rho")
print(rho_result, digits = 3)

# Context: first-order d' correlation across conditions
dprime_cor <- cor.test(corr_data$d1[, 1], corr_data$d1[, 2])
print(dprime_cor)

###########################################################################
# Supplementary S2: Stimulus differences per participant (Figure S3) -------
###########################################################################

# Mean absolute stimulus difference per participant and condition
stimdiff_by_subj <- trials %>%
  mutate(Condition = recode(as.character(condition), "1" = "Calories", "2" = "NRF")) %>%
  group_by(sID, Condition) %>%
  summarise(mean_abs_stimdiff = mean(abs(stimdiff), na.rm = TRUE), .groups = "drop")

stimdiff_by_subj %>%
  group_by(Condition) %>%
  summarise(M = mean(mean_abs_stimdiff), SD = sd(mean_abs_stimdiff),
            min = min(mean_abs_stimdiff), max = max(mean_abs_stimdiff), .groups = "drop") %>%
  print()

# save for plotting
save(stimdiff_by_subj, file = "Variables/stimdiff_by_subj.RData")

###########################################################################
# Supplementary S2: Burn-in sensitivity analysis (R2 Comment 3) ------------
###########################################################################

# Test whether the substantive results hold across burn-in choices
burnin_thresholds <- c(10, 20, 30)

burnin_results <- purrr::map_dfr(burnin_thresholds, function(n_burnin) {
  
  # Trim first n_burnin trials per subject × condition
  trials_trim <- trials %>%
    mutate(Condition = recode(as.character(condition), 
                              "1" = "Calories", "2" = "NRF")) %>%
    group_by(sID, Condition) %>%
    arrange(trial, .by_group = TRUE) %>%
    slice(-(1:n_burnin)) %>%
    ungroup()
  
  # --- Accuracy and d' ---
  sdt_stats_trim <- trials_trim %>%
    group_by(sID, Condition) %>%
    summarise(hits = sum(correct == 1),
              n_trials = n(),
              fas = sum(correct == 0),
              .groups = "drop") %>%
    mutate(hit_rate = pmin(pmax(hits / n_trials, 1/(2*n_trials)),
                           1 - 1/(2*n_trials)),
           fa_rate  = pmin(pmax(fas / n_trials, 1/(2*n_trials)),
                           1 - 1/(2*n_trials)),
           dprime   = qnorm(hit_rate) - qnorm(fa_rate),
           accuracy = hits / n_trials * 100)
  
  dprime_wide <- sdt_stats_trim %>%
    select(sID, Condition, dprime) %>%
    pivot_wider(names_from = Condition, values_from = dprime)
  acc_wide <- sdt_stats_trim %>%
    select(sID, Condition, accuracy) %>%
    pivot_wider(names_from = Condition, values_from = accuracy)
  
  t_dprime <- t.test(dprime_wide$Calories, dprime_wide$NRF, paired = TRUE)
  t_acc    <- t.test(acc_wide$Calories,    acc_wide$NRF,    paired = TRUE)
  
  # --- Confidence 2x2 ANOVA ---
  conf_trim <- trials_trim %>%
    mutate(Accuracy = ifelse(correct == 1, "Correct", "Incorrect")) %>%
    group_by(sID, Condition, Accuracy) %>%
    summarise(Confidence = mean(confidence, na.rm = TRUE), .groups = "drop") %>%
    mutate(sID = factor(sID), Condition = factor(Condition),
           Accuracy = factor(Accuracy))
  anova_conf <- ezANOVA(data = conf_trim, dv = Confidence, wid = sID,
                        within = .(Condition, Accuracy),
                        detailed = TRUE, type = 3)
  
  # --- RT 2x2 ANOVA ---
  rt_trim <- trials_trim %>%
    mutate(Accuracy = ifelse(correct == 1, "Correct", "Incorrect")) %>%
    group_by(sID, Condition, Accuracy) %>%
    summarise(RT = mean(RT, na.rm = TRUE), .groups = "drop") %>%
    mutate(sID = factor(sID), Condition = factor(Condition),
           Accuracy = factor(Accuracy))
  anova_rt <- ezANOVA(data = rt_trim, dv = RT, wid = sID,
                      within = .(Condition, Accuracy),
                      detailed = TRUE, type = 3)
  
  # --- Assemble results ---
  cal_acc_mean <- mean(acc_wide$Calories, na.rm = TRUE)
  nrf_acc_mean <- mean(acc_wide$NRF, na.rm = TRUE)
  
  tibble(
    n_burnin      = n_burnin,
    cal_acc       = cal_acc_mean,
    nrf_acc       = nrf_acc_mean,
    dprime_p      = t_dprime$p.value,
    acc_p         = t_acc$p.value,
    conf_cond_p   = anova_conf$ANOVA$p[anova_conf$ANOVA$Effect == "Condition"],
    conf_acc_p    = anova_conf$ANOVA$p[anova_conf$ANOVA$Effect == "Accuracy"],
    rt_acc_p      = anova_rt$ANOVA$p[anova_rt$ANOVA$Effect == "Accuracy"]
  )
})

print(burnin_results)

save(burnin_results, file = "Variables/burnin_sensitivity.RData")

###########################################################################
# Supplementary S3: Repeated stimulus pairs (R2 Comment 7) ------------------
###########################################################################

# --- Build pair-repetition dataset ---------------------------------------
# Create an unordered pair identifier so (item_A, item_B) == (item_B, item_A)
trials_pairs <- trials %>%
  mutate(Condition = recode(as.character(condition), 
                            "1" = "Calories", "2" = "NRF")) %>%
  # Find the corresponding item ids from ratings data if trials doesn't have them
  {
    if (all(c("item_left", "item_right") %in% names(.))) {
      .
    } else {
      left_join(., ratings %>% select(sID, trial, item_left, item_right),
                by = c("sID", "trial"))
    }
  } %>%
  mutate(pair_id = paste0(pmin(item_left, item_right), "_",
                          pmax(item_left, item_right))) %>%
  group_by(sID, Condition, pair_id) %>%
  arrange(trial, .by_group = TRUE) %>%
  mutate(repetition = row_number(),
         n_reps     = n()) %>%
  ungroup()

# Sanity check: how many pairs were seen 1, 2, 3+ times?
trials_pairs %>%
  distinct(sID, Condition, pair_id, n_reps) %>%
  count(Condition, n_reps) %>%
  print()

# Pairs shown more than three times (the task allowed up to three repeats):
# list their trials and check the same count for ordered (left/right) pairs
trials_pairs %>%
  filter(n_reps > 3) %>%
  select(sID, Condition, trial, item_left, item_right, repetition) %>%
  print()

trials_pairs %>%
  count(sID, Condition, item_left, item_right, name = "n_reps_ordered") %>%
  count(Condition, n_reps_ordered) %>%
  print()

# Restrict main analyses to repetitions 1-3 (drop the two n=1 NRF cells at reps 4 and 5)
trials_pairs_clean <- trials_pairs %>%
  filter(repetition <= 3)

# Keep only pairs seen at least twice for the repetition analyses
trials_repeated <- trials_pairs_clean %>%
  filter(n_reps >= 2)

# --- 1. Choice consistency across repetitions ----------------------------
# For each repeated pair, was the same item chosen as on the first exposure?
# Compare the chosen item, not the response key: left/right positions are
# randomised across repetitions, so the same key can mean a different item
trials_repeated <- trials_repeated %>%
  mutate(chosen_item = if_else(response == 1, item_left, item_right)) %>%
  group_by(sID, Condition, pair_id) %>%
  arrange(repetition, .by_group = TRUE) %>%
  mutate(first_choice  = first(chosen_item),
         same_as_first = as.integer(chosen_item == first_choice)) %>%
  ungroup()

# Reference: consistency expected if each choice were independent at the
# observed accuracy (p^2 + (1 - p)^2)
trials_repeated %>%
  group_by(Condition) %>%
  summarise(p_correct = mean(correct == 1, na.rm = TRUE),
            expected_consistency = p_correct^2 + (1 - p_correct)^2,
            .groups = "drop") %>%
  print()

# Model: probability of repeating first-exposure choice, by repetition and condition
# Using numeric repetition to test for a trend
consistency_data <- trials_repeated %>%
  filter(repetition > 1) %>%
  mutate(Condition  = factor(Condition),
         sID        = factor(sID))

model_consistency <- glmer(
  same_as_first ~ repetition * Condition + (1 | sID),
  data    = consistency_data,
  family  = binomial(link = "logit"),
  control = glmerControl(optimizer = "bobyqa")
)

summary(model_consistency)

# Descriptives
consistency_data %>%
  group_by(Condition, repetition) %>%
  summarise(prop_same = mean(same_as_first, na.rm = TRUE),
            n = n(), .groups = "drop") %>%
  print()

# --- 2. Confidence across repetitions ------------------------------------
# Using numeric repetition to test for a trend across exposures
# Rescale to [0,1] for ordered beta regression
trials_pairs_clean <- trials_pairs_clean %>%
  mutate(conf01 = (confidence - 1) / 99)

model_conf_rep <- glmmTMB(
  conf01 ~ repetition * Condition + (1 | sID) + (1 | pair_id),
  data   = trials_pairs_clean %>% mutate(Condition = factor(Condition),
                                         sID       = factor(sID)),
  family = ordbeta(link = "logit")
)

summary(model_conf_rep)

# Descriptives
trials_pairs_clean %>%
  group_by(Condition, repetition) %>%
  summarise(M_conf = mean(confidence, na.rm = TRUE),
            SD_conf = sd(confidence, na.rm = TRUE),
            n = n(), .groups = "drop") %>%
  print()

# --- 3. Individual variability -------------------------------------------
# Per-participant consistency proportion
indiv_consistency <- consistency_data %>%
  group_by(sID, Condition) %>%
  summarise(prop_same = mean(same_as_first, na.rm = TRUE),
            n = n(), .groups = "drop")

indiv_consistency %>%
  group_by(Condition) %>%
  summarise(M = mean(prop_same), SD = sd(prop_same),
            min = min(prop_same), max = max(prop_same),
            .groups = "drop") %>%
  print()

# Test whether individual variation in repetition effect is systematic:
# refit consistency model with random slope for repetition per subject
model_consistency_rs <- glmer(
  same_as_first ~ repetition * Condition + (1 + repetition | sID),
  data    = consistency_data,
  family  = binomial(link = "logit"),
  control = glmerControl(optimizer = "bobyqa")
)

# Compare to random-intercept-only model
anova(model_consistency, model_consistency_rs)

save(model_consistency, model_conf_rep, indiv_consistency,
     model_consistency_rs,
     file = "Variables/pair_repetition.RData")
