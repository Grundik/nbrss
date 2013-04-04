sql = require 'sql'

module.exports =
  users: sql.define(
    name: 'users'
    columns: ['id', 'jid', 'access']
  )

  subscriptions: sql.define(
    name: 'subscriptions'
    columns: ['id', 'url']
  )

  subscriptionsUsers: sql.define(
    name: 'subscriptions_users'
    columns: ['user_id', 'subscription_id']
  )