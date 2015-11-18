authenticateRoutes = (app) ->
  records = [
    { id: 1, username: process.env.AUTH_USERNAME, token: process.env.AUTH_TOKEN, emails: [ { value: process.env.AUTH_EMAIL } ] }
  ]

  findByToken = (token, cb) ->
    process.nextTick ->
      for i in [0 .. records.length]
        return cb(null, records[i]) if records[i].token is token
      return cb(null, null)

  passport = require 'passport'
  Strategy = require('passport-http-bearer').Strategy

  # Configure the Bearer strategy for use by Passport.
  #
  # The Bearer strategy requires a `verify` function which receives the
  # credentials (`token`) contained in the request.  The function must invoke
  # `cb` with a user object, which will be set at `req.user` in route handlers
  # after authentication.
  passport.use new Strategy (token, cb) ->
    findByToken token, (err, user) ->
      return cb err if err
      return cb null, false if !user
      return cb null, user
  ### ~@securitay; ###

  app.use require('morgan')('combined') 
  app.get '*', passport.authenticate('bearer', session: false), (req, res, next) ->
    next()

module.exports.authenticateRoutes = authenticateRoutes
