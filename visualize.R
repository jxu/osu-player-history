library(plotly)
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

# To make plotting easier, create new rows: every combination of player and date
# and add in usernames again
bar_race <- 
  player_history %>%
  filter(rank <= 10) %>%
  complete(id, date)

# Interpolate values (pp, etc.) only if consecutive snapshots are in top 10

test_df <- 
  bar_race %>%
  filter(id == 213014) %>%
  arrange(date) %>%
  mutate(in_top = !is.na(rank),
         mask = lead(in_top, default = FALSE) & in_top) %>%
  complete(date = seq(min(date), max(date), by = "day")) %>%
  fill(mask, id) %>%
  mutate(mask = (mask | in_top) %>% replace_na(FALSE),
         pp = if_else(mask, pp %>% tween_fill("linear"), NA_real_),
         accuracy = if_else(mask, accuracy %>% tween_fill("linear"), NA_real_),
         playcount = if_else(mask, playcount %>% tween_fill("linear"), NA_real_))



# testing data
# handling rank >= 10 to fly in from bottom
# need to handle imputing username
df <- player_history_10 %>% 
  filter(date <= ymd("20130101")) %>%
  complete(id, date, fill = list(rank = 1000, pp = 0)) 

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
 
