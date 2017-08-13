library(RSQLite)
library(data.table)
library(topicmodels)

# Connecting to the database 
conn <- dbConnect(SQLite(), dbname="tweetdb.sqlite")

# list all tables
alltables = dbListTables(conn) # "tweets"

# query all tweets and convert to data.tables
all.tweets <- data.table(dbGetQuery(conn = db, "select * from tweets"))

# Try topic models