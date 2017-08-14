# Twitter Analysis Demo

The project aims to demonstrate how to use real time social media data to have a quick glimpse of what people are talking about a specific topic right now. 
1. Download streaming data from Twitter.
2. Perform Latent Dirichlet Allocation (LDA) on the data, to quickly summarise different sub-topics.

This is put together during the Data Science HK unhackathon on 20170813.

# Python data download with tweepy

### Package dependencies

See requirements.txt

    pip install -r requirements.txt
    
    
### To download the data

Run download.py

    python src/download.py

### Wait while streaming API download

The downloaded data would be saved to tweetdb.sqlite as a sqlite database in a table called tweets.

# R data analysis

## Prerequisite

The following packages would be required

1. tidyverse
2. tidytext
3. TODO

## To Run the R Scripts

1. src/sql_to_csv.R - convert sqlite database into csv file called tweets.csv
2. src/word_cloud.R - shows word cloud of the tweets
3. src/topic_model.R - perform latent dirichlet allocation on the topic model



