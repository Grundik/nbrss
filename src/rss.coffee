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
userManager = null
seenCache = []

md5 = (data) ->
  hash = crypto.createHash 'md5'
  hash.update data
  hash.digest 'hex'

getString = (str, iconv)->
  if iconv then iconv.convert(str).toString('UTF-8') else str.toString('utf8')

cleanHtml = (str) ->
    str = str.replace(/<\/td>/ig, "</td> ")
             .replace(/&lt;p&gt;/ig, "\n&lt;p&gt;")
             .replace(/<p /ig, "\n<p ")
             .replace(/<p>/ig, "\n<p>")
             .replace(/<\/tr>/ig, "</tr>\n")
             .replace(/<\/table>/ig, "</table>\n")
             .replace(/<br \/>/ig, "\n")
             .replace(/<li /ig, "\n * <li ")
             .replace(/<li>/ig, "\n * <li>")
             .replace(/<br>/ig, "\n")
             .replace(/\s*<xhtml:link[^>]*href\s*=\s*['"]([^'"]+)['"][^>]*\/>\s*/ig, " \\1 ")
             .replace(/\s+<\/?[^>]*>\s*/mg, " ") # вырезает все теги обрамленные пробелами вместе с этими пробелами
             .replace(/<\/?[^>]*>/mg, "") # вырезает ваще все теги
    str = entities.decode str
    str = str.replace(/\r/g, "\n")
             .replace(/\n\s*\n/g, "\n")
    str

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

checkSeen = (feed, hash, cb) ->
  if seenCache.indexOf(hash) >= 0
    return cb true

  mh = tables.messageHash
  seen_sql =  mh.select(mh.time).from(mh)
               .where(mh.mhash.equals(hash))
               .and(mh.subscription_id.equals(feed.id))
               .limit(1)
  seenCache.push hash
  database.query(seen_sql.toQuery()).on 'end', (res) ->
    if res && res.length
      return cb true
    insert = mh.insert
      time: 'now'
      subscription_id: feed.id
      mhash: hash
    database.query(insert.toQuery()).on('error', ->
      null
    )
    cb false
  null

onScanDone = ->
  workers--
  onEndScan()
  null

doScanFeed = (feed, initiator) ->
  workers++
  url = feed.url
  console.log 'Scanning feed '+url
  cache_file = './cache/'+md5(url)
  fs.stat cache_file, (err, stat) ->
    rdata =
      url: url
      headers: {}
      encoding: null
    olddata = null
    if !err && stat && stat.mtime
      rdata.headers['if-modified-since'] = stat.mtime.toUTCString()
      olddata = md5 fs.readFileSync(cache_file)
      console.log "Old mtime=#{rdata.headers['if-modified-since']}"
      console.log "Old MD5=#{olddata}"
    request rdata, (error, response, body) ->
      if error
        console.log error
        return onScanDone()
      if response.statusCode != 200
        console.log "Got #{response.statusCode} status"
        return onScanDone()
      #fs.writeFile cache_file, body
      if response && response.headers && response.headers['content-type']
        conv = initConvert response.headers['content-type']
      string_data = getString body, conv
      newdata = md5(new Buffer string_data)
      console.log "New MD5=#{newdata}"
      if olddata && olddata == newdata
        console.log "Feed not changed"
        return onScanDone()
      fs.writeFile cache_file, string_data
      string_data = string_data.replace /encoding=(['"]?[a-z0-9-]+['"]?)/i, 'encoding="utf-8"'
      #console.log(string_data)
      Feedparser.parseString string_data, (error, meta, articles) ->
        #console.dir meta
        charset = null

        if !articles
          return onScanDone()

        parsed_articles = []
        title = (meta.title or '') + ' ' + (meta.description or '')
        if meta.link
          title += ' '+meta.link
        title = cleanHtml(title)
        toFill = articles.length
        console.log 'Got ' + toFill + ' articles'

        onArticleParsed = () ->
          if 0 == toFill
            console.log 'Sending messages to users...'
            userManager.getBySubscription feed.id, (user) ->
              user.deliverFeed parsed_articles, initiator == user.jid
            onScanDone()

        for article in articles.reverse()
          if  !article
            toFill--
            onArticleParsed()
            continue
          (->
            urls = cleanHtml(article.link || '')
            ititle = cleanHtml(article.title || '')
            text = cleanHtml(article.description || '')
            message = ititle + ' ' + urls + '\n\n' + text
            hash = md5 message
            seen = false
            checkSeen feed, hash, (seen) ->
              toFill--
              #console.log (if seen then 'S' else 'Uns')+'een article ('+toFill+' to go): '+title+'\n\n'+message
              parsed_articles.push
                title: title
                message: message
                hash: hash
                seen: seen
              onArticleParsed()
          )()
        null
        ###
        for article in articles
          console.log '-----'
          console.log outString(article.title) + ': '
          console.log outString(article.description)
          console.dir article
        ###

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

scanFeeds = (initiator, url) ->
  console.log 'Scanning feeds'
  s = tables.subscriptions
  sql = s.select(s.star()).from(s)
        .where('(SELECT COUNT(*) FROM subscriptions_users AS su WHERE su.subscription_id=subscriptions.id)>0')
  if url
    sql.and(s.url.equals(url))
  workers++
  #console.log sql.toQuery()
  database.query(sql.toQuery()).on('row', (row) ->
    doScanFeed row, initiator
  ).on('end', ->
    workers--
    onEndScan()
  )


module.exports =
  init: (db, xmpp_, interval, usermgr) ->
    database = db
    xmpp = xmpp_
    userManager = usermgr
    setScanInterval interval

  scanFeeds: (initiator)->
    scanDisabled = false
    scanFeeds(initiator)

  scanFeed: (url, initiator)->
    if !scanDisabled
      scanFeeds(initiator, url)

  stopScan: ->
    clearTimeout timeoutHandle
    scanDisabled = true
    timeoutHandle = null