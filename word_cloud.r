library(wordcloud)
library(tidyverse)

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

# Word cloud---------------------------------------------------
TD_matrix <- tweet	%>%
#	select(tweet) %>%
	as.matrix() %>%
	tm::VectorSource() %>%
	tm::Corpus() %>%
	tm::tm_map(tm::removeWords, tm::stopwords("english")) %>%
	tm::tm_map(tm::removeWords, c("amp", "The", "will", 'You','just', 'north', 'korea')) %>%
	tm::TermDocumentMatrix() %>%
	# tm::removeSparseTerms(sparse = 0.9995) %>%
	as.matrix()
	
v <- sort(rowSums(TD_matrix),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)

layout(matrix(c(1, 2), nrow=2), heights=c(1, 9))
par(mar=rep(0, 4))
plot.new()
text(x=0.5, y=0.5, paste0(date1, ', ', user))
wordcloud(words = d$word, freq = d$freq,
          max.words=40, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))

