library(dplyr)
library(readr)
library(RSQLite)

con <- src_sqlite("data/tweetdb.sqlite")

con %>%
  tbl('tweets') %>%
  collect() -> results

results %>% write_csv("data/tweets.csv")