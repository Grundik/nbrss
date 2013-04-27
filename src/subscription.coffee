sql = require 'sql'

subscriptions = null
database = null

tables = require './tables'

class Subscription
  constructor: (@url, cb) ->
    @id = 0
    s = tables.subscriptions
    insertsql = s.insert
      url: @url
    # console.log insertsql.toQuery()
    database.query(insertsql.toQuery()).on('end', =>
      # определяем назначенный id
      sql = s.select(s.star()).from(s).where(s.url.equals(@url)).limit(1)
      database.query(sql.toQuery()).on('row', (row) =>
        @id = row.id
      ).on('end', =>
        cb(this) if cb
      )
    )


module.exports =
  init: (db, cb) ->
    database = db
    s = tables.subscriptions
    sql = s.select(s.star()).from(s)
    subscriptions = {}
    database.query(sql.toQuery()).on('row', (row) ->
      subscriptions[row.url] = row
    ).on('end', ->
      cb() if cb
    )

  getSubscription: (url, cb) ->
    if subscriptions[url]
      cb subscriptions[url]
    else
      subscriptions[url] = new Subscription(url, cb)


