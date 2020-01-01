library(plotly)
library(tidyverse)
library(lubridate)
library(gganimate)

player_history <- read_csv("player_history.csv")

# convert date to date object
player_history <- 
  player_history %>% 
  mutate(date = ymd(date)) 

# user NUMBA WAN blatant cheater
# popular username mostly matches current username
username_map <- 
  player_history %>%
  group_by(id) %>%
  summarize(popular_username = 
              username %>% table %>% which.max %>% names,
            current_username = username[which.max(date)])

player_history <- 
  player_history %>%
  left_join(username_map, by = "id")


player_history_10 <- 
  player_history %>%
  filter(rank <= 10) 

# to not connect non-consecutive dates, create new rows: every combination of player and date
# and add in usernames again
player_history_10_complete <- 
  player_history_10 %>%
  complete(id, date) %>%
  select(-popular_username, -current_username) %>%
  left_join(username_map, by = "id")

# top 10 line graphs
ggplot(player_history_10_complete, 
       aes(x = date, y = pp, group = id, color = popular_username)) +
  geom_line() + 
  geom_vline(xintercept = ymd("20140127"), color = "gray") +
  annotate("text", x = ymd("20140127")+50, y = 6000, label = "ppv2")

ggplotly()

# testing data
df <- player_history_10 %>% 
  filter(date <= ymd("20120501")) 

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

animate(p, fps = 10, duration = 1)
 
