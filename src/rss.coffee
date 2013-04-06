feed = require 'feedparser'
Iconv = (require 'iconv').Iconv
request = require 'request'
crypto = require 'crypto'
sql = require 'sql'

tables = require './tables'

database = null
xmpp = null
timeoutHandle = null
workers = 0
autoScan = null
scanDisabled = false

md5 = (data) ->
  hash = crypto.createHash 'md5'
  hash.end data
  hash.digest 'hex'

doScanFeed = (feed) ->
  workers++
  url = feed.url
  console.log 'Scanning feed '+url
  cache_file = './cache/'+md5(url)
  request url, (error, response, body) ->
    workers--
  onEndScan()

onEndScan = ->
  if !autoScan || workers
    return
  clearTimeout timeoutHandle
  if scanDisabled
    return
  timeoutHandle = setTimeout scanFeeds, autoScan

setScanInterval = (interval) ->
  interval = Number interval
  if interval
    autoScan = if interval>60000 then interval else 60000
  else
    autoScan = nulls

scanFeeds = ->
  s = tables.subscriptions
  sql = s.select(s.star()).from(s)
        .where('(SELECT COUNT(*) FROM subscription_users AS su WHERE su.subscription_id=subscriptions.id)>0')
  workers++
  database.query(sql.toQuery()).on('row', (row) ->
    doScanFeed row
  ).on('end', ->
    workers--
    onEndScan()
  )


module.exports =
  init: (db, xmpp_, interval)
    database = db
    xmpp = xmpp_
    setScanInterval interval

  scanFeeds: ->
    scanDisabled = false
    scanFeeds

  stopScan: ->
    clearTimeout timeoutHandle
    scanDisabled = true
    timeoutHandle = null