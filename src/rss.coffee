Feedparser = require 'feedparser'
Iconv = (require 'iconv').Iconv
request = require 'request'
crypto = require 'crypto'
sql = require 'sql'
fs = require 'fs'

Entities = require('html-entities').XmlEntities
entities = new Entities();

tables = require './tables'

database = null
xmpp = null
timeoutHandle = null
workers = 0
autoScan = null
scanDisabled = false

md5 = (data) ->
  hash = crypto.createHash 'md5'
  hash.update data
  hash.digest 'hex'

getString = (str, iconv)->
  if iconv then iconv.convert(str).toString('UTF-8') else str.toString('utf8')

initConvert = (ctype) ->
  if !ctype
    return
  charset = /charset=(\S+)/i.exec ctype
  if !charset || !charset[1]
    return
  charset = charset[1]
  if charset && charset.toLowerCase() not in ['utf8', 'utf-8']
    console.log "recoding from #{charset}"
    return new Iconv(charset, 'UTF-8')
  null


outString = (str) ->
   str = str.replace /<br\s*\/?>/ig, '\n'
   entities.decode str

onScanDone = ->
  workers--
  onEndScan()
  null

doScanFeed = (feed) ->
  workers++
  url = feed.url
  console.log 'Scanning feed '+url
  cache_file = './cache/'+md5(url)
  fs.stat cache_file, (err, stat) ->
    rdata =
      url: url
      headers: {}
    olddata = null
    if !err && stat && stat.mtime
      rdata.headers['if-modified-since'] = stat.mtime.toUTCString()
      olddata = md5 fs.readFileSync(cache_file)
    request rdata, (error, response, body) ->
      if error
        console.log error
        return onScanDone()
      if response.statusCode != 200
        console.log "Got #{response.statusCode} status"
        return onScanDone()
      if olddata && olddata == md5 body
        console.log "Feed not changed"
        return onScanDone()
      fs.writeFile cache_file, body
      if response && response.headers && response.headers['content-type']
        conv = initConvert response.headers['content-type']
      string_data = getString body, conv
      string_data = string_data.replace /encoding=(['"]?[a-z0-9-]['"]?)/i, 'encoding="utf-8"'
      Feedparser.parseString string_data, (error, meta, articles) ->
        console.dir meta
        charset = null

        if !articles
          return onScanDone()

        #conv = initConvert meta['#content-type'] if meta && meta['#content-type']

        for article in articles
          console.log '-----'
          console.log outString(article.title) + ': '
          console.log outString(article.description)
        return onScanDone()

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
  console.log 'Scanning feeds'
  s = tables.subscriptions
  sql = s.select(s.star()).from(s)
        .where('(SELECT COUNT(*) FROM subscriptions_users AS su WHERE su.subscription_id=subscriptions.id)>0')
  workers++
  #console.log sql.toQuery()
  database.query(sql.toQuery()).on('row', (row) ->
    doScanFeed row
  ).on('end', ->
    workers--
    onEndScan()
  )


module.exports =
  init: (db, xmpp_, interval) ->
    database = db
    xmpp = xmpp_
    setScanInterval interval

  scanFeeds: ->
    console.log 'zzzzz'
    scanDisabled = false
    scanFeeds()

  stopScan: ->
    clearTimeout timeoutHandle
    scanDisabled = true
    timeoutHandle = null