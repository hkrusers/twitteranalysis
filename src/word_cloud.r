library(wordcloud)
library(tidyverse)
library(qdap)

input_text <- results

# Text cleaning ---------------------------------------------
tweet <- input_text$tweet %>%
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

# Word cloud---------------------------------------------------
TD_matrix <- tweet	%>%
	as.matrix() %>%
	tm::VectorSource() %>%
	tm::Corpus() %>%
	tm::tm_map(tm::removeWords, tm::stopwords("english")) %>%
	tm::tm_map(tm::removeWords, c("amp", "The", "will", 'You','just', 'north', 'korea')) %>%
	tm::TermDocumentMatrix() %>%
	# tm::removeSparseTerms(sparse = 0.9995) %>% # if you have a large matrix
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

