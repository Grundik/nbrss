xmpp = require 'simple-xmpp'

xmpp.on 'online', ->
  console.log 'Yes, I\'m connected!'

xmpp.on 'chat', (from, message) ->
  xmpp.send from, 'echo: ' + message

xmpp.on 'error', (err) ->
  console.error err

xmpp.on 'subscribe', (from) ->
  xmpp.acceptSubscription from
  xmpp.subscribe from

xmpp.connect(
    jid         : 'test@ololo.cc'
    password    : 'password'
    host        : 'im.ololo.cc'
    port        : 5222
)

#xmpp.subscribe 'your.friend@gmail.com'
# check for incoming subscription requests
xmpp.getRoster()

