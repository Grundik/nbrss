sql = require 'sql'
anyDB = require('any-db')

#console.dir(anyDB)
pool = anyDB.createPool 'postgres://test:test@localhost/test', {min: 5, max: 10}

finished = (err) ->
  if err
    console.error err
  else
    console.log 'All done!'
  if pool.end
    pool.end()
  else
    pool.close()

checker = (row, handler) ->
  setTimeout( ->
    handler(null, {flag: 1})
  , 1000)

testtable = sql.define(
  name: 'test1'
  columns: ['id', 'value']
)

sql = testtable.select(testtable.star()).from(testtable).toQuery()
console.log sql

worker = (tx) ->
  workers = 0
  query_done = false

  onJobDone = ->
    if !workers && query_done
      console.log 'Commiting transaction'
      if tx.commit
        tx.commit(finished)
      else
        finished()
    else
      console.log "Some jobs done: #{workers} workers active, main query #{if query_done then 'done' else 'in progress'}"

  pool.query(sql).on('row', (row) ->
      return if (tx && tx.state && tx.state().match('rollback'))

      console.log 'Got record ' + row.value

      workers++
      checker row, (err, result) ->
        return tx.handleError(err) if err
        console.log 'Updating record'
        if result.flag
          tx.query 'SELECT pg_sleep(5)', ->
            workers--
            onJobDone()
    ).on('error', (err) ->
      tx.handleError err
    ).on('end', ->
      query_done = true
      console.log 'Got query end'
      onJobDone()
    )

pool.begin (err, tx)->
  throw err if err?

  #tx = pool
  console.log 'Transaction started'
  tx.on('error', finished)
  worker(tx)
