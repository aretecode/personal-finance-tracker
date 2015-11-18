express = require 'express'
require './src/Persistence/env.coffee'

app = express()
router = express.Router()

{authenticateRoutes} = require('./app/authenticate.coffee')
authenticateRoutes(app)

{IncomeService, ExpenseService} = require('./src/Services.coffee')
incomeService = new IncomeService()
expenseService = new ExpenseService()

{incomeRoutes} = require('./app/income.coffee')
incomeRoutes(app, incomeService)

{expenseRoutes} = require('./app/expense.coffee')
expenseRoutes(app, expenseService)

{reportRoutes} = require('./app/report.coffee')
reportRoutes(app, incomeService, expenseService)

app.set 'port', (process.env.PORT || 5000)
app.listen app.get('port'), ->
  console.log 'Node app is running on port', app.get('port')