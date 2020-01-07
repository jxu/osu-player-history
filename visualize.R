library(tidyverse)
library(lubridate)
library(gganimate)
library(tweenr)

player_history <- read_csv("player_history.csv")

# convert date to date object
player_history <- 
  player_history %>% 
  mutate(date = ymd(date)) 

# popular username mostly matches current username
username_map <- 
  player_history %>%
  group_by(id) %>%
  summarize(popular_username = 
              username %>% table %>% which.max %>% names,
            current_username = username[which.max(date)])


#player_history <- 
#  player_history %>%
#  left_join(username_map, by = "id")


# Interpolate values (pp, etc.) *only if* consecutive snapshots are in top 10
# Mostly constant variables (username, country) use LOCF
interpolate_consecutive <- function(df) {
  df %>%
    arrange(date) %>%
    mutate(is_snapshot = !is.na(rank),
           in_top = lead(is_snapshot, default = FALSE) & is_snapshot) %>%
    complete(date = seq(min(date), max(date), by = "day"),
             fill = list(is_snapshot = FALSE)) %>%
    fill(in_top, 
         id,
         country,
         username) %>%
    # possibly use mutate_at
    mutate(in_top = (in_top | is_snapshot),
           pp = if_else(in_top, pp %>% tween_fill("linear"), NA_real_),
           accuracy = if_else(in_top, accuracy %>% tween_fill("linear"), NA_real_),
           playcount = if_else(in_top, playcount %>% tween_fill("linear"), NA_real_)) 
}

# test
top_n <- 10
df <- bar_race %>% filter(date == ymd("20120422")) 
# arrange puts NAs at bottom

df %>% arrange(pp) %>% 
  mutate(rank = c(1:top_n, rep(NA, nrow(df)-top_n))) %>% View


# Rank recalculation may result in inaccuracies since pp is interpolated
recalculate_rank <- function(df, top_n) {
  df %>% 
    arrange(desc(pp)) %>% 
    mutate(rank = c(1:top_n, rep(NA, nrow(df)-top_n)))
}

# To make plotting easier, "complete" dataframe by creating new rows: every combination of player and date 
# Interpolate days and further interpolate frames
bar_race <- 
  player_history %>%
  filter(rank <= 10) %>%
  complete(id, date) %>%
  group_by(id) %>%
  do(interpolate_consecutive(.)) %>%
  group_by(date) %>%
  do(recalculate_rank(., 10))






# animated bar chart (coord_flip is bugged)
p <- ggplot(df, aes(y = rank, group = id)) + 
  geom_tile(aes(x = pp / 2,
                height = 0.9, width = pp), fill = "pink") +
  geom_text(aes(x = 6000, label = username), 
            hjust = 0) + 
  geom_text(aes(x = pp, label = as.character(pp)), # tweening creates decimals (issue #204)
            hjust = 1) +
  ggtitle("{closest_state}") + 
  scale_y_reverse() +
  #coord_cartesian(expand = FALSE) + 
  view_step_manual(xmin = 6000, xmax = 7000, ymin = 1, ymax = 10) +
  theme_minimal() +
  transition_states(date, transition_length = 1, state_length = 1, wrap = FALSE) + 
  ease_aes("cubic-in-out")

animate(p, fps = 10, duration = 40)
 
