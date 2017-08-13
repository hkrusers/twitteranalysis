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

TextClean <- function(text_input){
  # Text cleaning ---------------------------------------------
  tweet <- sapply(text_input$tweet,as.character)
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
  
  remove.words <- c("amp", "The", "will", 'You','just', 'meekmouseracist', 
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
  
  
  # LDA function only takes rows as Docs and columns as Terms, transpose 
  TD_matrix <- t(TD_matrix)
  
  return(TD_matrix)
  
}


# Data Cleaning
TD_matrix <- TextClean(input_text)

# remove those with 0 row sums
TD_matrix <- TD_matrix[rowSums(TD_matrix) != 0, ]

ap_lda <- LDA(TD_matrix, k = 5, control = list(seed = 1234))

# Exploring 
ap_topics <- tidy(ap_lda, matrix = "beta")
ap_topics

# Grabbing top 10 words for each topic  
ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, desc(beta))

png("top_keywords.png", width = 1000, height = 1000)

ap_top_terms %>%
#  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(reorder(term, beta), beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()
dev.off()

library(tidyr)

beta_spread <- ap_topics %>%
  filter(topic %in% c(2,3)) %>%
  mutate(topic = paste0("topic", topic)) %>%
  spread(topic, beta) %>%
  filter(topic2 > .01 | topic3 > .01) %>%
  mutate(log_ratio = log2(topic2 / topic3))

beta_spread <- data.table(beta_spread)
beta_spread <- beta_spread[order(-log_ratio), ]

png(filename = "log_ratio.png", width = 1000, height = 1000)
ggplot(data = beta_spread, aes(x = reorder(term, -log_ratio), y = log_ratio)) +
  geom_col(show.legend = FALSE) +
  coord_flip()
dev.off()


# Document topic analysis 
ap_documents <- tidy(ap_lda, matrix = "gamma")

str.topics <- list(NULL)

for(i in c(1:length(unique(ap_documents$topic))))
{
  str.temp <- ap_documents %>% 
    filter(topic == i) %>%
    arrange(desc(gamma)) %>%
    head(1000) %>%
    select(document) %>% 
    unlist() %>% 
    as.numeric()
  
  str.topics[[i]] <- str.temp
}


# Word cloud---------------------------------------------------
png()
for(i in 1:length(str.topics)){
  TD_topics <- TextClean(input_text[str.topics[[i]],])
  TD_topics <- t(TD_topics )
  
  v <- sort(rowSums(TD_topics),decreasing=TRUE)
  d <- data.frame(word = names(v),freq=v)
  
  layout(matrix(c(1, 2), nrow=2), heights=c(1, 9))
  par(mar=rep(0, 4))
  plot.new()
#  text(x=0.5, y=0.5, paste0(date1, ', ', user))
  wordcloud(words = d$word, freq = d$freq,
            max.words=40, random.order=FALSE, rot.per=0.35, 
            colors=brewer.pal(8, "Dark2")) %>% print()
}


dev.off()


input_text[str.topics[[3]], tweet]



ap_documents <- data.table(ap_documents)


ap_documents[, .(mean(gamma), 
                 sd(gamma), 
                 max(gamma)), by =topic]

ap_documents[document == 2, ]
View(ap_documents)
ap_documents[topic == 1, ][order(-gamma)][c(1:10), ]




ap_documents[topic ==1, ][order()]





tidy(input_text) %>%
  filter(document == 6) %>%
  arrange(desc(count))
