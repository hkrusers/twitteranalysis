library(RSQLite)
library(data.table)
library(topicmodels)
library(tidyverse)
library(tidytext)
library(qdap)
library(tidyr)
library(wordcloud)
View(input_text)
#  ====== Loading inputData ====== 
# Connecting to the database 
conn <- dbConnect(SQLite(), dbname="data/tweetdb.sqlite")

# list all tables
alltables = dbListTables(conn) # "tweets"

# query all tweets and convert to data.tables
input_text <- data.table(dbGetQuery(conn, "select * from tweets"))

# # Load data 
# input_text <- data.table(read.csv("data/tweets.csv"))

#  ====== Cleaning Data  ====== 

# Function to clean data 
TextClean <- function(text_input){
  # Text cleaning ---------------------------------------------
  tweet <- text_input$tweet %>%
    gsub("@\\s.+\\shttp","http", .) %>% #Remove @place
    gsub("htt.*","", .) %>%
    gsub("@\\w+", " ", .) %>% #Remove @User
    gsub("#", " ", .) %>%
    gsub("\\!", "\\.", .) %>%
    gsub("\\?", "\\.", .) %>%
    iconv(., "latin1", "ASCII", sub="") %>%
    clean() %>%
    tolower() %>%
    replace_number(remove = TRUE) %>%
    scrubber() %>%
    incomplete_replace() %>%
    Trim() %>%
    bracketX(bracket = "all") %>%
    add_incomplete(silent = TRUE) %>%
    comma_spacer() %>%
    unname()
  
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


# ====== Using LDA to find 5 models  ======
# remove those with 0 row sums
TD_matrix <- TD_matrix[rowSums(TD_matrix) != 0, ]

# apply LDA model, tune groups by k
ap_lda <- LDA(TD_matrix, k = 5, control = list(seed = 1234))

#  ====== Explore by words  ======
ap_topics <- tidy(ap_lda, matrix = "beta")

# Grabbing top 10 words for each topic  
ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, desc(beta))

# Plotting the top keywords
png("plots/top_keywords.png", width = 1000, height = 1000)
ap_top_terms %>%
  #  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(reorder(term, beta), beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()
dev.off()

# Compre topics 2 and 3 using log ratio analysis 
beta_spread <- ap_topics %>%
  filter(topic %in% c(2,3)) %>%
  mutate(topic = paste0("topic", topic)) %>%
  spread(topic, beta) %>%
  filter(topic2 > .01 | topic3 > .01) %>%
  mutate(log_ratio = log2(topic2 / topic3))

beta_spread <- data.table(beta_spread)
beta_spread <- beta_spread[order(-log_ratio), ]

# Plot log ratio for topics 2 and 3 
png(filename = "plots/log_ratio.png", width = 1000, height = 1000)
ggplot(data = beta_spread, aes(x = reorder(term, -log_ratio), y = log_ratio)) +
  geom_col(show.legend = FALSE) +
  coord_flip()
dev.off()

# Document topic analysis 
ap_documents <- tidy(ap_lda, matrix = "gamma")

# Top 1000 topics from each group
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


# Generate Word Cloud for each group in a loop

# defining the location of the plot and plot name 
str.plot <- sprintf("plots/group%s.png", c(1:length(str.topics)))

for(i in 1:length(str.topics)){
  
  # write plot name
  png(str.plot[i])
  
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
  
  dev.off()
}


