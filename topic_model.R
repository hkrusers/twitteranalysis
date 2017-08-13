library(RSQLite)
library(data.table)
library(topicmodels)
library(tidyverse)
library(tidytext)

# Connecting to the database 
conn <- dbConnect(SQLite(), dbname="tweetdb.sqlite")

# list all tables
alltables = dbListTables(conn) # "tweets"

# query all tweets and convert to data.tables
input_text <- data.table(dbGetQuery(conn = db, "select * from tweets"))

# Try topic models

input_text <- data.table(read.csv("tweets.csv"))

# Converting tweets Term Document Matrix 
TD_matrix <- input_text	%>%
  select(tweet) %>%
  as.matrix() %>%
  tm::VectorSource() %>%
  tm::Corpus() %>%
  tm::tm_map(tm::removeWords, tm::stopwords("english")) %>%
  tm::tm_map(tm::removeWords, c("amp", "The", "will", 'You','just', 'https')) %>%
  tm::TermDocumentMatrix() %>%
  # tm::removeSparseTerms(sparse = 0.9995) %>%
  as.matrix()

# LDA function only takes rows as Docs and columns as Terms, transpose 
TD_matrix <- t(TD_matrix)

ap_lda <- LDA(TD_matrix, k = 4, control = list(seed = 1234))

# Exploring 
ap_topics <- tidy(ap_lda, matrix = "beta")
ap_topics

ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()

