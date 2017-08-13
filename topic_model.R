library(RSQLite)
library(data.table)
library(topicmodels)
library(tidyverse)
library(tidytext)
library(qdap)


# Connecting to the database 
conn <- dbConnect(SQLite(), dbname="tweetdb.sqlite")

# list all tables
alltables = dbListTables(conn) # "tweets"

# query all tweets and convert to data.tables
input_text <- data.table(dbGetQuery(conn = db, "select * from tweets"))

# Try topic models

input_text <- data.table(read.csv("tweets.csv"))

# Data Cleaning
{
  # Text cleaning ---------------------------------------------
  tweet <- sapply(input_text$tweet,as.character)
  tweet <- sapply(tweet, function(x) gsub("@\\s.+\\shttp","http",x))  #Remove @place
  tweet <- sapply(tweet, function(x) gsub("htt.*","",x))
  tweet <- sapply(tweet, function(x) gsub("@\\w+", " ", x))  #Remove @User
  tweet <- sapply(tweet, function(x) gsub("#", " ", x))
  tweet <- sapply(tweet, function(x) gsub("\\!", "\\.", x))
  tweet <- sapply(tweet, function(x) gsub("\\?", "\\.", x))
  tweet <- sapply(tweet, function(row) iconv(row, "latin1", "ASCII", sub=""))
  tweet <- clean(tweet)
  tweet <- tolower(tweet)
  tweet <- replace_number(tweet, remove = TRUE)
  tweet <- scrubber(tweet)
  tweet <- incomplete_replace(tweet)
  tweet <- Trim(tweet)
  tweet <- bracketX(tweet,bracket = "all")
  tweet <- add_incomplete(tweet,silent = TRUE)
  tweet <- comma_spacer(tweet)
  tweet <- unname(tweet)
  
  remove.words <- c("amp", "The", "will", 'You','just', 
                    'north', 'korea', '...', 'like')
  
  # Word cloud---------------------------------------------------
  TD_matrix <- tweet	%>%
    #	select(tweet) %>%
    as.matrix() %>%
    tm::VectorSource() %>%
    tm::Corpus() %>%
    tm::tm_map(tm::removeWords, tm::stopwords("english")) %>%
    tm::tm_map(tm::removeWords, remove.words) %>%
    tm::TermDocumentMatrix() %>% 
    # tm::removeSparseTerms(sparse = 0.9995) %>%
    as.matrix()
}


# LDA function only takes rows as Docs and columns as Terms, transpose 
TD_matrix <- t(TD_matrix)

# remove those with 0 row sums
TD_matrix <- TD_matrix[rowSums(TD_matrix) != 0, ]

ap_lda <- LDA(TD_matrix, k = 3, control = list(seed = 1234))

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

