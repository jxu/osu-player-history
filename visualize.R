library(tidyverse)
library(lubridate)

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

# to not connect non-consecutive dates, create new rows: every combination of player and date
# and add in usernames again
player_history_10 <- 
  player_history %>%
  filter(rank <= 10) %>%
  complete(id, date) %>%
  select(-popular_username, -current_username) %>%
  left_join(username_map, by = "id")


library(plotly)
ggplot(player_history_10, aes(x = date, y = pp, group = id, color = popular_username)) +
  geom_line() + 
  geom_vline(xintercept = ymd("20140127"), color = "gray") +
  annotate("text", x = ymd("20140127")+50, y = 6000, label = "ppv2")

ggplotly()
