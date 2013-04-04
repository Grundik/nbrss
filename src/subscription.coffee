sql = require 'sql'

subscriptions = null
database = null

tables = require 'tables'

module.exports =
  getSubscription: (url, cb) ->
    getSub = ->
      if subscriptions[jid]
        cb subscriptions[jid]
      else
        subscriptions[jid] = new Subscription(url, cb)
    if subscriptions?
      getSub()
    else
      s = tables.subscriptions
      sql = s.select(s.star()).from(s)
      subscriptions = []
      database.query(sql.toQuery()).on('row', (row) ->
        subscriptions.push(row)
      ).on('end', ->
        getSub()
      )

  setDatabase: (db) ->
    database = db
