CONFIG = require 'config'
anyDB = require 'any-db'
xmpp = require 'simple-xmpp'
usermgr = require './user'
subsmgr = require './subscription'
feedmgr = require './rss'

shutdown = () ->
  console.log 'Shutting down...'
  xmpp.conn.end() if xmpp
  database.end() if database

xmpp.on 'online', ->
  console.log 'XMPP connected'
  feedmgr.scanFeeds()

xmpp.on 'chat', (from, message) ->
  message = message.trim()
  cmd = (message.toLowerCase().match /^(\S+)/)
  args = (message.match(/^\S+\s+(.*)$/))
  cmd = if cmd && cmd[1] then cmd[1] else message
  args = if args && args[1] then args[1] else ''

  usermgr.getUser from, (user) ->
    return null unless user
    if 'die' == cmd && user.access >= 10
      console.log 'Received shutdown request'
      xmpp.send from, 'Пакапака'
      shutdown()
    else if 'list' == cmd
      user.getSubscriptions (subscriptions) ->
        xmpp.send from, 'Подписки: ' + (if subscriptions.length then subscriptions.join('\n') else 'нет ни одной')
    else if 'subscribe' == cmd
      user.addSubscription args, (s, exists) ->
        xmpp.send from, 'Подписка на ' + args + ' ' +
                        (if exists then 'добавлена' else 'уже есть') +
                        ' (' + s.id + ')'
        if !exists
          feedmgr.scanFeed(s.url, user.jid)
    else if 'unsubscribe' == cmd
      user.delSubscription args, (exists) ->
        xmpp.send from, 'Подписка на ' + args + ' ' +
                        (if exists then 'удалена' else 'отсутствовала')
    else
      xmpp.send from, 'Нипаняяятна: ' + message
      xmpp.send from, 'Возможные команды: list, subscribe, unsubscribe'

xmpp.on 'error', (err) ->
  console.error err
  feedmgr.stopScan()

xmpp.on 'subscribe', (from) ->
  console.log 'Accepting subscribe request from '+from
  xmpp.acceptSubscription from
  xmpp.subscribe from

#console.dir(anyDB)
database = anyDB.createConnection CONFIG.db.adapter+'://' + CONFIG.db.user + ':' + CONFIG.db.password + '@' + CONFIG.db.host + '/' + CONFIG.db.name
usermgr.init database, xmpp

feedmgr.init database, xmpp, 5*60000, usermgr
subsmgr.init database, ->
  xmpp.connect
    jid         : CONFIG.xmpp.jid
    password    : CONFIG.xmpp.password
    host        : CONFIG.xmpp.host
    port        : CONFIG.xmpp.port || 5222
  xmpp.getRoster()

#xmpp.subscribe 'your.friend@gmail.com'
# check for incoming subscription requests

