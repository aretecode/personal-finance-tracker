require 'coffee-script/register'
express = require 'express'

# for env vars
require('./src/connection.coffee')

### ~@securitay ###

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

app = express()
router = express.Router()

app.use require('morgan')('combined') 
app.get '*', passport.authenticate('bearer', session: false), (req, res, next) ->
  next()

balanceTrend = require('./src/balanceTrend.coffee').balanceTrend
MonthYearRange = require('./src/balanceTrend.coffee').MonthYearRange
{Income, Expense, FinanceOperation, AbstractFinanceOperationFactory} = require('./src/model.coffee')
{FinanceOperationService, FinanceService, IncomeService, ExpenseService} = require('./src/db.coffee')
Factory = AbstractFinanceOperationFactory
incomeService = new IncomeService()
expenseService = new ExpenseService()

### 
@REPORTS 
@TODO: be able to just specify an end date
###
app.get '/api/reports/balance/trend/:startmonth?-:startyear?,:endmonth?-endyear?', (req, res) ->
  if not req.params.endmonth? 
    monthYearRange = new MonthYearRange(req.params.startmonth, req.params.startyear, req.params.endmonth, req.params.endyear)
  else 
    monthYearRange = new MonthYearRange()

  balanceTrend incomeService, expenseService, ((result) -> res.send result), monthYearRange

app.get '/api/reports/incomes/monthly/:month?/:year?', (req, res) ->
  month = if req.params.month? then req.params.month else null
  year = if req.params.year? then req.params.year else null
  console.log month, year
  incomeService.reports month, year, (report) -> res.send report

app.get '/api/reports/expenses/monthly/:month?/:year?', (req, res) ->
  month = if req.params.month? then req.params.month else null
  year = if req.params.year? then req.params.year else null
  console.log month, year
  expenseService.reports month, year, (report) -> res.send report


### @INCOME ###
app.get '/api/incomes/create/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) -> create(req.params, res)
app.put '/api/incomes/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) -> create(req.params, res)
create = (p, res) ->
  incomingIncome = Factory.income p.id, p.currency, p.amount, p.tags, p.date, p.description
  incomeService.save incomingIncome, (saved) ->
    res.send saved

app.get '/api/incomes/delete/:id', (req, res) ->
  incomeService.deleteWithId req.params.id, (deleted) -> res.send (deleted)
app.delete '/api/incomes/:id', (req, res) ->
  incomeService.deleteWithId req.params.id, (deleted) -> res.send (deleted)

### @TODO: improve, accept ?params to set individual ones under :id/###
app.get '/api/incomes/update/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> update(req.params, res)
app.patch '/api/incomes/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> update(req.params, res)
update = (p, res) ->
  incomingIncome = Factory.income null, p.currency, p.amount, p.tags, p.created_at, p.description
  incomeService.save incomingIncome, (updated) -> res.send(updated)

app.get '/api/incomes/retrieve/:id', (req, res) ->
  incomeService.findWithId req.params.id, (found) -> res.send found

app.get '/api/incomes/list*', (req, res) ->
  if req.query.date?
    incomeService.listWithDate new Date(req.query.date), (result) -> res.send result 
  else if req.query.tag?
    incomeService.listWithTag req.query.tag, (result) -> res.send result 
  else # default
    incomeService.list (result) -> res.send result 







### @EXPENSES ###
app.get '/api/expenses/create/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) -> create(req.params, res)
app.put '/api/expenses/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) -> create(req.params, res)
create = (p, res) ->
  incomingexpense = Factory.expense p.id, p.currency, p.amount, p.tags, p.date, p.description
  expenseService.save incomingexpense, (saved) -> res.send saved

app.get '/api/expenses/delete/:id', (req, res) ->
  expenseService.deleteWithId req.params.id, (deleted) -> res.send (deleted)
app.delete '/api/expenses/:id', (req, res) ->
  expenseService.deleteWithId req.params.id, (deleted) -> res.send (deleted)

### @TODO: improve, accept ?params to set individual ones under :id/###
app.get '/api/expenses/update/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> update(req.params, res)
app.patch '/api/expenses/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> update(req.params, res)
update = (p, res) ->
  incomingexpense = Factory.expense null, p.currency, p.amount, p.tags, p.created_at, p.description
  expenseService.save incomingexpense, (updated) -> res.send(updated)

app.get '/api/expenses/retrieve/:id', (req, res) ->
  expenseService.findWithId req.params.id, (found) -> res.send found

app.get '/api/expenses/list*', (req, res) ->
  if req.query.date?
    expenseService.listWithDate new Date(req.query.date), (result) -> res.send result 
  else if req.query.tag?
    expenseService.listWithTag req.query.tag, (result) -> res.send result 
  else # default
    expenseService.list (result) -> res.send result 








### @LISTENING 5000 ###
app.set 'port', (process.env.PORT || 5000)
app.listen app.get('port'), ->
  console.log 'Node app is running on port', app.get('port')