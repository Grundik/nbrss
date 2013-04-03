feed = require 'feedparser'
Iconv = (require 'iconv').Iconv
#http = require 'http'
request = require 'request'

Entities = require('html-entities').XmlEntities;
entities = new Entities();

iconv = null

getString = (str)->
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
    iconv = new Iconv(charset, 'UTF-8')
  null

outString = (str) ->
   str = str.replace /<br\s*\/?>/ig, '\n'
   entities.decode str

url = {
  url: 'http://bash.org.ru/rss/'
  encoding: null
}

request url, (error, response, body) ->
  if response && response.headers && response.headers['content-type']
    initConvert response.headers['content-type']
  ###
  console.dir result.headers
  data = []
  len = 0
  result.on 'data', (chunk) ->
    len += chunk.length
    data.push chunk

  result.on 'end', ->
    totalbuf = new Buffer len
    pos = 0
    for b in data
      b.copy totalbuf, pos
      pos += b.length
  ###
  string_data = getString(body)
  string_data = string_data.replace /encoding=(['"]?[a-z0-9-]['"]?)/i, 'encoding="utf-8"'

  feed.parseString string_data, (error, meta, articles) ->
    console.dir meta
    charset = null

    if !articles
      return

    initConvert meta['#content-type'] if meta && meta['#content-type']

    for article in articles
      console.log '-----'
      console.log outString(article.title) + ': '
      console.log outString(article.description)
    null
    #console.dir articles
