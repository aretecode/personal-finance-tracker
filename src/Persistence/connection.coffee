require('./env.coffee')

conn = {
  host: process.env.DATABASE_HOST
  user: process.env.DATABASE_USER
  password: process.env.DATABASE_PASSWORD
  database: process.env.DATABASE_NAME
  charset: 'utf8'
}

pg = require('knex')({client: 'pg', connection: conn, debug: false})
getPg = () -> return pg
module.exports.getPg = getPg
