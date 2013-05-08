RSS to XMPP feed aggregator written in nodejs.

Installation:
1. clone repository
2. copy config/default.yaml-default to config/default.yaml
3. set up database and xmpp accounts in config/default.yaml
4. import database schema (rss.sql)
5. install node modules: npm i
6. run: coffee src/rssbot.coffee
7. add rss bot to your roster

Usage:
Send commands to xmpp account:
* subscribe url — subscribe to rss feed at url
* list — list subscriptions
* unsubscribe url — remove subscription to feed at url
