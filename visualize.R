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


# Rank recalculation may result in inaccuracies since pp is interpolated
recalculate_rank <- function(df, top_n) {
  df %>% 
    arrange(desc(pp)) %>% 
    mutate(rank = c(1:top_n, rep(NA, nrow(df)-top_n)))
}

# To make plotting easier, "complete" dataframe by creating new rows: every combination of player and date 
# Interpolate days and further interpolate frames
# bar_race <- 
#   player_history %>%
#   filter(rank <= 10) %>%  # remove later
#   complete(id, date) %>%
#   group_by(id) %>%
#   do(interpolate_consecutive(.)) %>%
#   group_by(date) %>%
#   do(recalculate_rank(., 10))



# To make interpolation easier, "complete" dataframe by creating new rows: every combination of player and date 
# interpolate: 
bar_race <- 
  player_history %>%
  filter(rank <= 20 & date < ymd("20130101")) %>%  # for testing, remove later
  complete(id, date = seq(min(date), max(date), by = "day")) %>%
  arrange(date, desc(pp)) %>% # optional at this point
  group_by(id) %>%
  mutate_at(vars(country, username, accuracy, playcount, pp), 
            ~ tween_fill(., "linear"))


#interpolate over frames

bar_race <- 
  bar_race %>%
  mutate(frame_ = date)


# place bars manually 
bar_race <-
  bar_race %>% 
  ungroup() %>%
  group_by(date) %>% 
  arrange(desc(pp)) %>%
  mutate(rank = 1:n(),
         bar_pos = rank)



# testing animated bar chart
p <- ggplot(bar_race, aes(y = rank)) + 
  geom_tile(aes(x = pp / 2,
                height = 0.9, width = pp), fill = "pink") +
  geom_text(aes(x = 5000, label = username), 
            hjust = 0) + 
  geom_text(aes(x = pp, label = as.character(round(pp))),
            hjust = 1) +
  geom_text(aes(x = 6000, y = 10, label = frame_), check_overlap = TRUE) +
  scale_y_reverse(breaks = 1:10) + 
  coord_cartesian(xlim = c(5000, 7000), ylim = c(1, 10)) + 
  theme_minimal() +
  transition_manual(frame_)

animate(p, fps = 10, nframes = length(unique(bar_race$frame_)), renderer = gifski_renderer())
 
