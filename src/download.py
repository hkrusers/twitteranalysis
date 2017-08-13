from tweepy import Stream
from tweepy import OAuthHandler
from tweepy.streaming import StreamListener
#import MySQLdb
import time
import json
import pandas as pd
import yaml
import sqlalchemy
import os.path

with open(os.path.split(os.path.dirname(__file__))[0] + '/parameters/config.yml', 'r') as ymlfile:
    cfg = yaml.load(ymlfile)

print(cfg)
# consumer key, consumer secret, access token, access secret.
ckey = cfg['ckey']
csecret = cfg['csecret']
atoken = cfg['atoken']
asecret = cfg['asecret']

results = []

pathdb = 'sqlite:///' + os.path.split(os.path.dirname(__file__))[0] + '/data/tweetdb.sqlite'

engine = sqlalchemy.create_engine(pathdb)

class listener(StreamListener):
    def on_data(self, data):
        all_data = json.loads(data)

        tweet = all_data["text"]

        username = all_data["user"]["screen_name"]

        print((username, tweet))
        pd.DataFrame({'time': [time.time()],
                        'username': [username],
                        'tweet': [tweet]}).to_sql('tweets', engine, if_exists='append', index=False)

        return True

    def on_error(self, status):
        print(status)


auth = OAuthHandler(ckey, csecret)
auth.set_access_token(atoken, asecret)

twitterStream = Stream(auth, listener())
twitterStream.filter(track=["North Korea"])
