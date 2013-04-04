sql = require 'sql'
subsmgr = require './subscription'

users = {}
database = null

tables = require './tables'


class User
  constructor: (@jid, cb) ->
    @access = 0
    @id = 0
    u = tables.users
    sql = u.select(u.star()).from(u).where(u.jid.equals(@jid)).limit(1).toQuery()
    #console.log sql
    found = false
    database.query(sql).on('row', (row) =>
      @access = row.access
      @id = row.id
      found = true
    ).on('end', =>
      if !found
        insertsql = u.insert
          jid: @jid
          access: 0
        # console.log insertsql.toQuery()
        database.query(insertsql.toQuery()).on('end', =>
          # определяем назначенный id
          database.query(sql).on('row', (row) =>
            @id = row.id
          ).on('end', =>
            cb(this) if cb
          )
        )
      else
        cb(this) if cb
    )

  getSubscriptions: (cb) ->
    return cb @subscriptions if @subscriptions
    u = tables.users
    su = tables.subscriptionsUsers
    s = tables.subscriptions
    sql = s.select(s.star()).from(s.join(su).on(s.id.equals(su.subscription_id)))
                         .where(su.user_id.equals(@id))
    #console.log sql.toQuery()
    @subscriptions = []
    database.query(sql.toQuery()).on('row', (row) =>
      @subscriptions.push(row)
    ).on('end', =>
      cb(@subscriptions)
    )

  addSubscription: (url, cb) ->
    subsmgr.getSubscription url, (s) =>
      @getSubscriptions (allsubs) =>
        found = false
        for n in allsubs
          if s.url == n.url
            cb(s, false) if cb
            found = true
            break
        if !found
          su = tables.subscriptionsUsers
          insertsql = su.insert
            user_id: @id
            subscription_id: s.id
          # console.log insertsql.toQuery()
          database.query(insertsql.toQuery()).on 'end', =>
            @subscriptions.push(s)
            cb(s, true) if cb

  delSubscription: (url, cb) ->
    subsmgr.getSubscription url, (s) =>
      @getSubscriptions (allsubs) =>
        found = false
        for sub, n in allsubs
          if s.url == sub.url
            su = tables.subscriptionsUsers
            @subscriptions.splice(n, 1)
            delsql = su.delete().where(su.user_id.equals(@id)).and(su.subscription_id.equals(s.id))
            database.query(delsql.toQuery()).on 'end', =>
              cb(true) if cb
            found = true
            break
        if !found
          cb(false) if cb

module.exports =
  getUser: (jid, cb) ->
    if users[jid]
      cb users[jid]
    else
      users[jid] = new User(jid, cb)
  setDatabase: (db) ->
    database = db
