###########################################################################
# Plot MetaBites Figures --------------------------------------------------
###########################################################################

# Clean the environment
rm(list = ls())

# Setup & Libraries
set.seed(123)  # reproducibility 

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(gghalves)
library(ggsignif)
library(patchwork)
library(HDInterval)


# Helper functions
# -----------------------------------------------------------------------------
# recoding of condition variables
recode_condition <- function(x) {dplyr::recode(x, "cal" = "Calories", "nrf" = "NRF", .default = x)}

# central theme  
my_theme <- function(base_size = 15) {theme_classic(base_size = base_size) +
    theme(text = element_text(family = "arimo"),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
      axis.title = element_text(face = "bold", size = 13),
      axis.text = element_text(size = 12), axis.line = element_line(linewidth = 1.5, colour = "black"))}


# Load in data
# -----------------------------------------------------------------------------
master_path <- file.path("Data", "MetaBites_master.xlsx")
trial_path <- file.path("Data", "MetaBites_triallevel_master.xlsx")
stimratings_path <- file.path("Data", "MetaBites_ratings_master.xlsx")
stim_path <- file.path("Data", "stim_data.xlsx")
ratings_path <- file.path("Data", "MetaBites_trialratings.xlsx")
demo_path <- file.path("Data", "demographics.csv")

master <- readxl::read_excel(master_path)                    # task level data
trials <- readxl::read_excel(trial_path)                     # trial level data ################
stimratings <- readxl::read_excel(stimratings_path)          # task level data with ratings ############################################
stim_data <- readxl::read_excel(stim_path)                   # stimulus information ############################################
demo <- read.csv(demo_path, stringsAsFactors = FALSE)        # demographic data
demo <- demo[, c(1:3)]
colnames(demo)[1] <- "sID"

# Combine master + demo into subj_data
subj_data <- dplyr::inner_join(demo, master, by = 'sID')
# rename SB columns (as in your original)
colnames(subj_data)[16:25] <- c("SB_1_cal","SB_1_nrf", "SB_2_cal","SB_2_nrf",
                                "SB_3_cal","SB_3_nrf", "SB_4_cal","SB_4_nrf", "SB_5_cal","SB_5_nrf")


###########################################################################
# Figure 1 ----------------------------------------------------------------
###########################################################################

# ----------------------------
# 1A: Empty for task schematic 
# ----------------------------
blank_panel <- ggplot() + 
  theme_void() + 
  labs(title = "Schematic task overview", tag = "A") +
  my_theme()

# ----------------------------
# 1B: Calories distribution 
# ----------------------------
calories_plot <- ggplot(stim_data, aes(x = calories, 
                                       fill = "Calories", 
                                       colour = "Calories")) +
  geom_histogram(alpha = 0.7, position = "identity", bins = 30) +
  scale_fill_manual(values = c("Calories" = "#D95F02")) +
  scale_color_manual(values = c("Calories" = "#D95F02")) +
  labs(title = "Distribution of Calories",
       x = "Calories/100g",
       y = "Count",
       tag = "B") +
  my_theme() +
  theme(legend.position = "none", plot.title = element_text(size=11), axis.title = element_text(size = 11))

# ----------------------------
# 1C: NRF distribution
# ----------------------------
nrf_plot <- ggplot(stim_data, aes(x = nrf, 
                                  fill = "NRF", 
                                  colour = "NRF")) +
  geom_histogram(alpha = 0.7, position = "identity", bins = 30) +
  scale_fill_manual(values = c("NRF" = "#1B9E77")) +
  scale_color_manual(values = c("NRF" = "#1B9E77")) +
  labs(title = "Distribution of NRF index",
       x = "NRF/100g",
       y = "Count",
       tag = "C") +
  my_theme() +
  theme(legend.position = "none", plot.title = element_text(size=11), axis.title = element_text(size = 11))

# ----------------------------
# 1D: Stimulus Correlation
# ----------------------------
correlation_plot <- ggplot(stim_data, aes(x = calories, y = nrf)) +
  geom_point(color = "#2F4F4F", fill = "#2F4F4F", alpha = 0.6, size = 2, shape = 21) +
  geom_smooth(method = "lm", se = TRUE, color = "#2F4F4F", alpha = 0.2, linewidth = 1.2) +
  labs(title = "Correlation of Calories and NRF", x = "Calories/100g", y = "NRF/100g", tag = "D") +
  annotate("text", x = 470, y = 285, label = "r = -0.4", fontface = "bold", size = 4, hjust = 0) +
  annotate("text", x = 470, y = 250, label = "p < .001", fontface = "bold", size = 4, hjust = 0) +
  my_theme() + theme(plot.title = element_text(size=11), axis.title = element_text(size = 11))

# combine plots
figure_1 <-  blank_panel / (calories_plot +  nrf_plot + correlation_plot) + plot_layout() 
figure_1

# save
ggsave(filename = "Figures/Figure_1bcd.png",
       plot = figure_1,
       width = 850 * 3.3,
       height = 530 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

###########################################################################
# Figure 2 ----------------------------------------------------------------
###########################################################################

# ----------------------------
# 2A: d'
# ----------------------------
load("Variables/dprime.RData")

a_plot <- ggplot(dprime_data, aes(x = cond_label, y = dprime, fill = cond_label, color = cond_label)) +
  geom_half_violin(side = "r", alpha = 0.85, trim = FALSE) +
  geom_half_boxplot(side = "r", width = 0.15, position = position_dodge(0.3), linewidth = 0.7, color = "black", fill = "white", outlier.shape = T) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  coord_cartesian(ylim = c(0.6, 1.7)) +   # zoom only; ylim() would drop data before the violins/boxplots are computed
  labs(title = "Perceptual Sensitivity", x = "Condition", y = "d'", tag = "A") +
  geom_signif(comparisons = list(c("Calories", "NRF")), annotations = "**", y_position = 1.6, tip_length = 0.03, textsize = 5, , fontface = "bold", color = "black", size = 1, map_signif_level = FALSE) +
  my_theme()+
  theme(legend.position = "none")

# ----------------------------
# 2B: accuracy per block 
# ----------------------------
load("Variables/acc_long.RData")

b_plot <- ggplot(acc_long, aes(x = block, y = accuracy, color = condition)) +
  geom_point(alpha = 0.3, size = 1.3, position = "jitter") +
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar", width = 0.2, size = 0.8) +
  stat_summary(fun = mean, geom = "line", aes(group = condition), linewidth = 1) +
  stat_summary(fun = mean, geom = "point", size = 2.5) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(title = "Accuracy per Block", x = "Block Number", y = "Accuracy (%) ± 95% CI", color = "Condition", fill = "Condition", tag = "B") +
  coord_cartesian(ylim = c(50, 90)) +   # zoom only, so block means/CIs use all data
  my_theme() +
  theme(legend.position = "left")

# ----------------------------
# 2C: RT and accuracy
# ----------------------------
load("Variables/rt_long.RData")

# numeric Accuracy and jitter
rt_long$Accuracy_num <- ifelse(rt_long$Accuracy == "Correct", 1, 2)
rt_long$x_jittered <- ifelse(rt_long$Condition == "Calories",
  rt_long$Accuracy_num - 0.2 + runif(nrow(rt_long), -0.02, 0.02),
  rt_long$Accuracy_num + 0.1 + runif(nrow(rt_long), -0.02, 0.02))

# for significance bracket
y_top_c  <- max(rt_long$RT, na.rm = TRUE)
y_rng_c  <- diff(range(rt_long$RT, na.rm = TRUE))
y_bracket_c <- y_top_c + 0.06 * y_rng_c     # horizontal bracket line
y_tickh_c   <- 0.03 * y_rng_c             # small vertical ticks height
y_text_c    <- y_top_c + 0.098 * y_rng_c    # text above bracket

c_plot <- ggplot(rt_long, aes(x = x_jittered, y = RT, fill = Condition, group = interaction(sID, Condition))) +
  geom_line(color = "grey87", linewidth = 0.4, alpha = 0.7) +
  geom_half_boxplot(aes(x = Accuracy_num, group = interaction(Condition, Accuracy)), side = "r", notch = TRUE, outlier.shape = NA, width = 0.3, position = position_dodge(0.6), linewidth = 0.7) +
  geom_point(aes(color = Condition, group = interaction(Condition, Accuracy)), shape = 21, size = 2, alpha = 0.6) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_x_continuous(breaks = c(1, 2), labels = c("Correct", "Incorrect"), limits = c(0.5, 2.5)) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.12))) +
  coord_cartesian(ylim = c(1.1, 3)) +   # was ylim(1.3, 3), which dropped RTs < 1.3 s (min = 1.18) from the boxplots
  labs(title = "Reaction Time by Accuracy", x = "Accuracy", y = "RT (s)", tag = "C") +
  annotate("segment", x = 1, xend = 2, y = y_bracket_c, yend = y_bracket_c, color = "black", size = 1) +
  annotate("segment", x = 1, xend = 1, y = y_bracket_c, yend = y_bracket_c - y_tickh_c, color = "black", size = 1) +
  annotate("segment", x = 2, xend = 2, y = y_bracket_c, yend = y_bracket_c - y_tickh_c, color = "black", size = 1) +
  annotate("text", x = 1.5, y = y_text_c, label = "***", size = 5, fontface = "bold") +
  my_theme() +
  theme(legend.position = "none")

# ----------------------------
# 2D: Confidence and accuracy
# ----------------------------
load("Variables/conf_long.RData")

# numeric Accuracy and jitter
conf_long$Accuracy_num <- ifelse(conf_long$Accuracy == "Correct", 1, 2)
conf_long$x_jittered <- ifelse(conf_long$Condition == "Calories",
  conf_long$Accuracy_num - 0.2 + runif(nrow(conf_long), -0.02, 0.02),
  conf_long$Accuracy_num + 0.1 + runif(nrow(conf_long), -0.02, 0.02))

# for significance bracket
y_top_d  <- max(conf_long$Confidence, na.rm = TRUE)
y_rng_d  <- diff(range(conf_long$Confidence, na.rm = TRUE))
y_bracket_d <- y_top_d + 0.06 * y_rng_d     # horizontal bracket line
y_tickh_d   <- 0.03 * y_rng_d             # vertical tick height
y_text_d    <- y_top_d + 0.098 * y_rng_d    # text above bracket

d_plot <- ggplot(conf_long, aes(x = x_jittered, y = Confidence, fill = Condition, group = interaction(sID, Condition))) +
  geom_line(color = "grey87", linewidth = 0.4, alpha = 0.7) +
  geom_half_boxplot(aes(x = Accuracy_num, group = interaction(Condition, Accuracy)), side = "r", notch = TRUE, outlier.shape = NA, width = 0.3, position = position_dodge(0.6), linewidth = 0.7) +
  geom_point(aes(color = Condition, group = interaction(Condition, Accuracy)), shape = 21, size = 2, alpha = 0.6) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_x_continuous(breaks = c(1, 2), labels = c("Correct", "Incorrect"), limits = c(0.5, 2.5)) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.12))) +  
  coord_cartesian(ylim = c(33, 100)) +
  labs(title = "Confidence by Accuracy", x = "Accuracy", y = "Confidence", tag = "D") +
  annotate("segment", x = 1, xend = 2, y = y_bracket_d, yend = y_bracket_d, color = "black", size = 1) +
  annotate("segment", x = 1, xend = 1, y = y_bracket_d, yend = y_bracket_d - y_tickh_d, color = "black", size = 1) +
  annotate("segment", x = 2, xend = 2, y = y_bracket_d, yend = y_bracket_d - y_tickh_d, color = "black", size = 1) +
  annotate("text", x = 1.5, y = y_text_d, label = "***", size = 5, fontface = "bold") +
  my_theme() +
  theme(legend.position = "none")

# Combine panels and show
figure_2 <- (a_plot + b_plot) / (c_plot + d_plot) + plot_layout(guides = "collect")
figure_2

# save
ggsave(filename = "Figures/Figure_2.png",
       plot = figure_2,
       width = 850 * 3.3,
       height = 600 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")


###########################################################################
# Figure 3 (ratings) -----------------------------------------------------
###########################################################################

# ----------------------------
# 3A: ratings correlation
# ----------------------------
# mutate data
ratings_summary <- stimratings %>%
  group_by(stim_number) %>%
  summarise(familiarity = mean(familiarity, na.rm = TRUE),
            liking = mean(liking, na.rm = TRUE), calories = first(calories), nrf = first(nrf))

# Determine position for annotation (top-left corner)
x_pos <- min(stimratings$familiarity, na.rm = TRUE) + 
  0.05 * (max(stimratings$familiarity, na.rm = TRUE) - min(stimratings$familiarity, na.rm = TRUE))
y_pos <- max(stimratings$liking, na.rm = TRUE) - 
  0.05 * (max(stimratings$liking, na.rm = TRUE) - min(stimratings$liking, na.rm = TRUE)) - 0.35
annotation_text <- paste0("r = ", "0.47", ", ", "p < .001")

liking_familiarity_plot <- ggplot(ratings_summary, aes(x = familiarity, y = liking)) +
  geom_point(color = "#2F4F4F", fill = "#2F4F4F", alpha = 0.6, size = 3, shape = 21) +
  geom_smooth(method = "lm", se = TRUE, color = "#2F4F4F", alpha = 0.2, linewidth = 1.2) +
  annotate("text", x = x_pos, y = y_pos, 
           label = annotation_text, 
           fontface = "bold", size = 5, hjust = 0) +
  labs(title = "Familiarity and Liking by Stimulus", 
    x = "Familiarity", 
    y = "Liking",
    tag = "A") +
  my_theme()

# ----------------------------
# 3B: Condition check
# ----------------------------
load("Variables/ratings_long.RData")
load("Variables/summary_stats.RData")

liking_color <- "#5EA09E"     
familiarity_color <- "#2F4F4F"  

condition_plot <- ggplot(ratings_long, aes(x = Condition, y = rating, color = measure, fill = measure)) +
  geom_point(position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.6, seed = 123),
    alpha = 0.45, size = 1.7, shape = 21) +
  geom_point(data = summary_stats,
    aes(y = mean_rating),
    position = position_dodge(width = 0.6),
    size = 6, shape = 21) +
  geom_errorbar(data = summary_stats,
    aes(y = mean_rating, ymin = ci_lower, ymax = ci_upper),
    position = position_dodge(width = 0.6),
    width = 0.2, linewidth = 1.2) +
  scale_color_manual(values = c("Liking" = liking_color, "Familiarity" = familiarity_color)) +
  scale_fill_manual(values = c("Liking" = liking_color, "Familiarity" = familiarity_color)) +
  labs(title = "Familiarity and Liking by Condition",
    x = "Condition",
    y = "Mean Rating ± 95% CI",
    color = "Measure",
    fill = "Measure",
    tag = "B") +
  my_theme()

# ----------------------------
# 3C: Familiarity on choice
# ----------------------------
load("Variables/pred_data_fam_combined.RData")
load("Variables/empirical_familiarity.RData")

familiarity_choice_plot <- ggplot() +
  geom_line(data = pred_data_fam_combined,
            aes(x = abs_familiarity_diff, y = prob_chose_higher_fam, color = Condition),
            linewidth = 1.2) +
  geom_point(data = empirical_familiarity,
             aes(x = abs_familiarity_diff_mean, y = prob_chose_higher, fill = Condition),
             shape = 21, size = 3, alpha = 0.6) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0.02, 0.02))) +
  labs(title = "Effect of Familiarity on Choice",
       x = "|Δ| Familiarity",
       y = "P(Choose More Familiar)",
       tag = "C") +
  my_theme() +
  theme(legend.position = "none")

# ----------------------------
# 3D: Liking on choice
# ----------------------------
load("Variables/pred_data_combined.RData")
load("Variables/empirical_liking.RData")

liking_choice_plot <- ggplot() +
  geom_line(data = pred_data_combined,
            aes(x = abs_liking_diff, y = prob_chose_higher_liking, color = Condition),
            linewidth = 1.2) +
  geom_point(data = empirical_liking,
             aes(x = abs_liking_diff_mean, y = prob_chose_higher, fill = Condition),
             shape = 21, size = 3, alpha = 0.6) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0.02, 0.02))) +
  labs(title = "Effect of Liking on Choice",
       x = "|Δ| Liking",
       y = "P(Choose More Liked)",
       tag = "D") +
  my_theme() +
  theme(legend.position = "none")

# ----------------------------
# 3E: Familiarity on confidence
# ----------------------------
# Prediction lines and binned observed confidence, computed in Analysis_main.R
load("Variables/fam_conf_plotdata.RData")

fam_conf_plot <- ggplot() +
  geom_line(data = pred_fam_conf, aes(x = abs_familiarity_diff, y = pred_confidence, color = Condition), linewidth = 1.5) +
  geom_point(data = fam_conf_binned, aes(x = mid, y = mean_conf, fill = Condition), shape = 21, size = 3.5, alpha = 0.6) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(title = "Effect of Familiarity on Confidence", x = "|Δ| Familiarity", y = "Confidence", tag = "E") +
  my_theme() +
  theme(legend.position = "none")

# ----------------------------
# 3F: Liking on confidence
# ----------------------------
like_conf_plot <- ggplot() +
  geom_line(data = pred_like_conf, aes(x = abs_liking_diff, y = pred_confidence, color = Condition), linewidth = 1.5) +
  geom_point(data = like_conf_binned, aes(x = mid, y = mean_conf, fill = Condition), shape = 21, size = 3.5, alpha = 0.6) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(title = "Effect of Liking on Confidence", x = "|Δ| Liking", y = "Confidence", tag = "F") +
  my_theme() +
  theme(legend.position = "right")

figure_3 <- (liking_familiarity_plot + condition_plot) /
  (familiarity_choice_plot + liking_choice_plot) /
  (fam_conf_plot + like_conf_plot) +
  plot_layout(guides = "collect")
figure_3

# --- Save 
ggsave(
  filename = "Figures/Figure_3.png",
  plot     = figure_3,
  width    = 1061* 3,
  height   = 699 * 4.5,
  dpi      = 300,
  units    = "px",
  bg       = "white"
)


###########################################################################
# Figure 4 (SB / blockwise) -----------------------------------------------
###########################################################################

# ----------------------------
# 4A: Global confidence updating
# ----------------------------
# mutate
sb_long <- subj_data %>%
  select(sID, SB_pre_cal, SB_pre_nrf, SB_post_cal, SB_post_nrf) %>%
  pivot_longer(cols = -sID, names_to = c("Time", "Condition"),names_pattern = "SB_(pre|post)_(cal|nrf)", values_to = "SB") %>%
  mutate(Time = factor(Time, levels = c("pre", "post"), labels = c("Pre", "Post")),
         Condition = recode_condition(Condition), Time_num = ifelse(Time == "Pre", 1, 2))

sb_long$x_jittered <- ifelse(sb_long$Condition == "Calories",
  sb_long$Time_num - 0.2 + runif(nrow(sb_long), -0.02, 0.02),
  sb_long$Time_num + 0.1 + runif(nrow(sb_long), -0.02, 0.02))

plot_a <- ggplot(sb_long, aes(x = x_jittered, y = SB, fill = Condition)) +
  stat_summary(aes(x = Time_num, group = Condition, color = Condition), fun = mean, geom = "line", linewidth = 1.3, position = position_dodge(0.4)) +
  stat_summary(aes(x = Time_num, group = Condition, color = Condition), fun.data = mean_cl_normal, geom = "errorbar", width = 0.2, size = 0.7, position = position_dodge(0.4), linewidth = 1.3) +
  stat_summary(aes(x = Time_num, group = Condition, color = Condition), fun = mean, geom = "point", size = 3, position = position_dodge(0.4)) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_x_continuous(breaks = c(1, 2), labels = c("Pre", "Post"), limits = c(0.5, 2.5)) +
  labs(title = "Global confidence updating", x = "Time", y = "Task-level Global Confidence ± 95% CI", tag = "A") +
  my_theme()

# ----------------------------
# 4B: Global-local correlation
# ----------------------------
load("Variables/merged_data.RData")

# for annotation
y_top <- max(merged_data$SB_value, na.rm = TRUE)
y_rng <- diff(range(merged_data$SB_value, na.rm = TRUE))
y_text_cal <- y_top + 0.001 * y_rng
y_text_nrf <- y_top + 0.07 * y_rng

plot_b <- ggplot(merged_data, aes(x = conf_value, y = SB_value, fill = Condition)) +
  geom_point(aes(color = Condition), alpha = 0.6, size = 2, shape = 21) +
  geom_smooth(method = "lm", se = TRUE, aes(color = Condition), alpha = 0.2, linewidth = 1.2) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(title = "Blockwise Global and Local Confidence", x = "Mean Local Confidence (per block)", y = "Block-level Global Confidence", tag = "B") +
  annotate("text", x = 0.40 * max(merged_data$conf_value), y = y_text_cal, label = "r = 0.58, p < .001", color = "#D95F02", hjust = 0, size = 4, fontface = "bold") +
  annotate("text", x = 0.40 * max(merged_data$conf_value), y = y_text_nrf, label = "r = 0.58, p < .001", color = "#1B9E77", hjust = 0, size = 4, fontface = "bold")+
  my_theme() +
  theme(legend.position = "none")

figure_4 <- plot_a + plot_b + plot_layout(guides = "collect")
figure_4

# save
ggsave(filename = "Figures/Figure_4.png",
       plot = figure_4,
       width = 1079 * 3.3,
       height = 473 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

###########################################################################
# Figure 5  ---------------------------------------------------------------
###########################################################################
load("Variables/mratio_diff.RData")
load("Variables/mratio_post.RData")

hdi_vals <- mratio_post %>%
  group_by(Condition) %>%
  summarise(
    lower = hdi(Mratio, credMass = 0.95)["lower"],
    upper = hdi(Mratio, credMass = 0.95)["upper"],
    mean  = mean(Mratio)
  )

# Y positions for HDI segments (staggered so they don't overlap; the two
# HDIs overlap on the x-axis)
hdi_vals <- hdi_vals %>%
  mutate(y_pos = ifelse(Condition == "Calories", -200, -450))


fig_5a <- ggplot(mratio_post, aes(x = Mratio, fill = Condition, colour = Condition)) +
  geom_histogram(alpha = 0.5, position = "identity", bins = 40) +
  # 95% HDI (bar with end ticks) and posterior mean (diamond) per condition
  geom_segment(data = hdi_vals, aes(x = lower, xend = upper, y = y_pos, yend = y_pos, colour = Condition),
               linewidth = 1.5, inherit.aes = FALSE) +
  geom_segment(data = hdi_vals, aes(x = lower, xend = lower, y = y_pos - 30, yend = y_pos + 30, colour = Condition),
               linewidth = 1.2, inherit.aes = FALSE) +
  geom_segment(data = hdi_vals, aes(x = upper, xend = upper, y = y_pos - 30, yend = y_pos + 30, colour = Condition),
               linewidth = 1.2, inherit.aes = FALSE) +
  geom_point(data = hdi_vals, aes(x = mean, y = y_pos, colour = Condition),
             size = 3, shape = 18, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  scale_color_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(title = "Metacognitive Efficiency", x = "Group-level Mratio", y = "Count", tag = "A") +
  coord_cartesian(ylim = c(-550, 4600)) +   # zoom only; ylim() would drop histogram bars above the limit
  my_theme() +
  theme(legend.position = "right",
        legend.key.size = unit(0.4, "cm"),
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 11))

fig_5b <- ggplot(delta_df, aes(x = delta)) +
  geom_histogram(alpha = 0.5, bins = 40, fill = "#2F4F4F", colour = "#2F4F4F") +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 1, colour = "black") +
  geom_segment(aes(x = hdi_diff["lower"], xend = hdi_diff["upper"], y = -200, yend = -200),
               linewidth = 1.5, colour = "#2F4F4F", inherit.aes = FALSE) +
  geom_segment(aes(x = hdi_diff["lower"], xend = hdi_diff["lower"], y = -230, yend = -170),
               linewidth = 1.2, colour = "#2F4F4F", inherit.aes = FALSE) +
  geom_segment(aes(x = hdi_diff["upper"], xend = hdi_diff["upper"], y = -230, yend = -170),
               linewidth = 1.2, colour = "#2F4F4F", inherit.aes = FALSE) +
  geom_point(aes(x = mean_diff, y = -200), size = 3, shape = 18,
             colour = "#2F4F4F", inherit.aes = FALSE) +
  labs(title = "Mratio Difference Distribution",
       x = "log(Mratio) Difference (Calories - NRF)",   # delta is mu_logMratio, i.e. on the log scale
       y = "Count", tag = "B") +
  ylim(c(-300, NA)) +
  my_theme()

figure_5 <- fig_5a + fig_5b + plot_layout()
figure_5

# save
ggsave(filename = "Figures/Figure_5.png",
       plot = figure_5,
       width = 927 * 3.3,
       height = 379 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

###########################################################################
# Supplementary ----------------------------------------------------------
###########################################################################

# ----------------------------
# S1A: Empty panels for matlab plots
# ----------------------------
blank_panelA <- ggplot() + 
  theme_void() + 
  labs(tag = "A") +
  my_theme()


blank_panelB <- ggplot() + 
  theme_void() + 
  labs(tag = "B") +
  my_theme()

supp_fig_1 <- blank_panelA + blank_panelB + plot_layout()
supp_fig_1

# save
ggsave(filename = "Figures/Figure_S1.png",
       plot = supp_fig_1,
       width = 600 * 3.3,
       height = 300 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

# ----------------------------
# S2: Staircases
# ----------------------------
# Compute global y-limits for each condition across all participants
condition_limits <- trials %>%
  mutate(condition = factor(condition, levels = c(1, 2), labels = c("Calories", "NRF"))) %>%
  group_by(condition) %>%
  summarise(ymin = min(stimdiff, na.rm = TRUE),
            ymax = max(stimdiff, na.rm = TRUE),
            .groups = "drop")

plot_participant_staircasing <- function(participant_id, data) {
  participant_data <- data %>%
    filter(sID == participant_id) %>%
    mutate(condition = factor(condition, levels = c(1, 2), labels = c("Calories", "NRF")))
  
  thresholds <- participant_data %>%
    filter(reversal == 1) %>%
    group_by(condition) %>%
    summarise(threshold = mean(stimdiff, na.rm = TRUE), .groups = "drop")
  
  lims <- condition_limits
  
  if ("block" %in% names(participant_data)) {
    plot_data <- participant_data %>%
      group_by(condition, block) %>%
      arrange(trial, .by_group = TRUE) %>%
      mutate(trial_idx = dplyr::row_number()) %>%
      ungroup() %>%
      left_join(thresholds, by = "condition") %>%
      left_join(lims, by = "condition")
    
    p <- ggplot(plot_data, aes(x = trial_idx, y = stimdiff)) +
      geom_line(color = "black", linewidth = 0.9, alpha = 0.95) +
      geom_point(aes(color = factor(reversal)),
                 size = 2.2, stroke = 0.3, alpha = 0.95) +
      geom_hline(aes(yintercept = threshold), color = "red",
                 linetype = "22", linewidth = 0.9, alpha = 0.95) +
      facet_grid(condition ~ block, scales = "free_x") +
      scale_color_manual(values = c(`0` = "black", `1` = "red"),
                         labels = c(`0` = "No", `1` = "Yes"),
                         name = "Reversal") +
      labs(title = paste("Staircases for Participant", participant_id),
           x = "Trial (within block)",
           y = "Absolute Stimulus Difference") +
      my_theme() +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(linewidth = 0.25, color = "grey85"),
        panel.grid.major.y = element_line(linewidth = 0.25, color = "grey90"),
        strip.background = element_rect(fill = "grey95", color = NA),
        strip.text = element_text(face = "bold"),
        legend.position = "none"
      )
  } else {
    plot_data <- participant_data %>%
      group_by(condition) %>%
      arrange(trial, .by_group = TRUE) %>%
      mutate(trial_idx = dplyr::row_number()) %>%
      ungroup() %>%
      left_join(thresholds, by = "condition") %>%
      left_join(lims, by = "condition")
    
    p <- ggplot(plot_data, aes(x = trial_idx, y = stimdiff)) +
      geom_line(color = "black", linewidth = 0.7, alpha = 0.95) +
      geom_point(aes(color = factor(reversal)),
                 size = 1.7, stroke = 0.3, alpha = 0.95) +
      geom_hline(aes(yintercept = threshold), color = "red",
                 linetype = "22", linewidth = 0.7, alpha = 0.95) +
      facet_wrap(~ condition, scales = "free_x", ncol = 2) +
      scale_color_manual(values = c(`0` = "black", `1` = "red"),
                         labels = c(`0` = "No", `1` = "Yes"),
                         name = "Reversal") +
      labs(title = paste("Staircases for Participant", participant_id),
           x = "Trial",
           y = "Absolute Stimulus Difference") +
      my_theme() +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(linewidth = 0.25, color = "grey85"),
        panel.grid.major.y = element_line(linewidth = 0.25, color = "grey90"),
        strip.background = element_rect(fill = "grey95", color = NA),
        strip.text = element_text(face = "bold"),
        legend.position = "none"
      )
  }
  return(p)
}

# Get all unique participant IDs
participant_ids <- unique(trials$sID)

# Plot a 2x2 panel, legend removed
set.seed(97)
ids4 <- sample(participant_ids, 4)
ids4 <- ids4[order(as.numeric(ids4))]

supp_fig_2 <- patchwork::wrap_plots(purrr::map(ids4, ~ plot_participant_staircasing(.x, trials)), ncol = 2, nrow = 2, guides = "collect") & theme(legend.position = "none")
supp_fig_2

# save
ggsave(filename = "Figures/Figure_S2.png",
       plot = supp_fig_2,
       width = 1130 * 3.3,
       height = 642 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

# ----------------------------
# S3: Stimulus differences
# ----------------------------

load("Variables/stimdiff_by_subj.RData")

# --- S3A: Calories condition
calories_stimdiff_plot <- ggplot(
  stimdiff_by_subj %>% filter(Condition == "Calories"),
  aes(x = Condition, y = mean_abs_stimdiff, 
      fill = Condition, color = Condition)) +
  geom_half_violin(side = "r", alpha = 0.85, trim = FALSE) +
  geom_half_boxplot(side = "r", width = 0.15, 
                    position = position_dodge(0.3),
                    linewidth = 0.7, color = "black", fill = "white",
                    outlier.shape = TRUE) +
  scale_fill_manual(values = c("Calories" = "#D95F02")) +
  scale_color_manual(values = c("Calories" = "#D95F02")) +
  labs(title = "Calories condition",
       x = "Condition",
       y = "Mean absolute stimulus difference (kcal/100g)",
       tag = "A") +
  my_theme() +
  theme(legend.position = "none")

# --- S3B: NRF condition
nrf_stimdiff_plot <- ggplot(
  stimdiff_by_subj %>% filter(Condition == "NRF"),
  aes(x = Condition, y = mean_abs_stimdiff, 
      fill = Condition, color = Condition)) +
  geom_half_violin(side = "r", alpha = 0.85, trim = FALSE) +
  geom_half_boxplot(side = "r", width = 0.15, 
                    position = position_dodge(0.3),
                    linewidth = 0.7, color = "black", fill = "white",
                    outlier.shape = TRUE) +
  scale_fill_manual(values = c("NRF" = "#1B9E77")) +
  scale_color_manual(values = c("NRF" = "#1B9E77")) +
  labs(title = "NRF condition",
       x = "Condition",
       y = "Mean absolute stimulus difference (units/100g)",
       tag = "B") +
  my_theme() +
  theme(legend.position = "none")

# --- Combine
figure_S3 <- calories_stimdiff_plot + nrf_stimdiff_plot + plot_layout()
figure_S3

ggsave(filename = "Figures/Figure_S3.png",
       plot = figure_S3,
       width = 932 * 3.3,
       height = 481 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")

# ----------------------------
# S4: Confidence integration
# ----------------------------
load("Variables/boot_samples.RData")

supp_fig_4 <- ggplot(
  boot_samples,
  aes(x = Window, y = r_boot, fill = Condition)
) +
  geom_boxplot(
    notch = TRUE,
    width = 0.5,
    outlier.shape = NA,
    alpha = 0.85,
    linewidth = 0.92,
    position = position_dodge2(width = 0.7, padding = 0.25, preserve = "single")
  ) +
  scale_fill_manual(values = c("Calories" = "#D95F02", "NRF" = "#1B9E77")) +
  labs(
    title = "Global Confidence Information Integration",
    x = "Block Segment",
    y = "Correlation (Local vs. Global)",
    fill = "Condition"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.12))) +
  my_theme() +
  theme(legend.position = "right")

supp_fig_4

# save
ggsave(filename = "Figures/Figure_S4.png",
       plot = supp_fig_4,
       width = 712 * 3.3,
       height = 473 * 3.3,
       dpi = 300,
       units = "px",
       bg = "white")
