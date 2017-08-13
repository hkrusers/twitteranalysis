library(dplyr)
library(readr)
con <- src_sqlite("tweetdb.sqlite")

con %>%
  tbl('tweets') %>%
  collect() -> results


results %>% write_excel_csv("tweets.csv")

