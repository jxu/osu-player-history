library(tidyverse)
library(lubridate)

player_history <- read_csv("player_history.csv")

# convert to date object
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
  full_join(username_map, by = "id")


player_history_10 <- 
  player_history %>%
  filter(rank <= 10)

ggplot(player_history_10, aes(x = date, y = pp, group = id, color = popular_username)) +
  geom_line()
