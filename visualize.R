library(tidyverse)
library(lubridate)
library(gganimate)
library(tweenr)

player_history <- read_csv("player_history.csv")

# convert date to date object
player_history <- 
  player_history %>% 
  mutate(date = ymd(date)) 

# maybe useful: popular username mostly matches current username
username_map <- 
  player_history %>%
  group_by(id) %>%
  summarize(popular_username = 
              username %>% table %>% which.max %>% names,
            current_username = username[which.max(date)])


# To make interpolation easier, "complete" dataframe by creating new rows: 
# every combination of player and date 
# interpolate: 
history_day <- 
  player_history %>%
  filter(rank <= 20 & date < ymd("20130101")) %>%  # for testing, remove later
  complete(id, date = seq(min(date), max(date), by = "day")) %>%
  arrange(date, desc(pp)) %>% # optional at this point
  group_by(id) %>%
  mutate_at(vars(country, username, accuracy, playcount, pp), 
            ~ tween_fill(., "linear")) %>%
  ungroup()


# create more frames between days
# TODO: interpolate between days?
bar_race <- 
  history_day %>%
  slice(rep(row_number(), 4)) %>%
  group_by(id) %>%
  arrange(date) %>%
  mutate(frame = row_number()) %>%
  ungroup()

# testing moving average
# TODO: fix first and end NAs

wts <- c(1, 1, 1:5, 4:1, 1, 1)
ma <- function(x){ stats::filter(x, wts/sum(wts), sides = 2) %>% as.vector }



# recalculate rank for every frame
bar_race <-
  bar_race %>% 
  group_by(frame) %>% 
  arrange(desc(pp)) %>%
  mutate(rank = row_number()) %>%  # TODO: assign unknown ranks the same value
  ungroup() %>%

  # then make nice bar position transitions
  group_by(id) %>%
  arrange(frame) %>%
  mutate(bar_pos = ma(rank)) %>%
  ungroup()
  

# testing animated bar chart
p <- ggplot(bar_race, aes(y = bar_pos)) + 
  geom_tile(aes(x = pp / 2,
                height = 0.9, width = pp), fill = "pink") +
  geom_text(aes(x = 5000, label = username), 
            hjust = 0) + 
  geom_text(aes(x = pp, label = as.character(round(pp))),
            hjust = 1) +
  geom_text(aes(x = 6000, y = 10, label = frame), check_overlap = TRUE) +
  scale_y_reverse(breaks = 1:10) + 
  coord_cartesian(xlim = c(5000, 7000), ylim = c(1, 10)) + 
  theme_minimal() +
  transition_manual(frame)

animate(p, fps = 30, nframes = max(bar_race$frame), renderer = gifski_renderer())
 
