{MonthYearRange} = require('./../src/Report/MonthYearRange.coffee')
{balanceTrend} = require('./../src/Report/balanceTrend.coffee')

reportRoutes = (app, incomeService, expenseService) ->
  app.get '/api/reports/balance/trend', (req, res) ->
    balanceTrend incomeService, expenseService, ((result) -> res.send result.code, result.body)

  app.get '/api/reports/balance/trend/:startmonth?-:startyear?,:endmonth?-:endyear?', (req, res) ->
    monthYearRange = new MonthYearRange(
      req.params.startmonth, 
      req.params.startyear, 
      req.params.endmonth, 
      req.params.endyear)
    
    balanceTrend incomeService, expenseService, ((result) -> 
      res.send result.code, result.body), monthYearRange

  app.get '/api/reports/incomes/monthly/:month?/:year?', (req, res) ->
    reports 'incomes', req.params, res

  app.get '/api/reports/expenses/monthly/:month?/:year?', (req, res) -> 
    reports 'expenses', req.params, res

  reports = (type, p, res) ->
    month = if p.month? then p.month else null
    year = if p.year? then p.year else null
    if type is 'income'
      expenseService.reports month, year, (report) -> 
        res.send report.code, report.body
    else 
      incomeService.reports month, year, (report) -> 
        res.send report.code, report.body

module.exports.reportRoutes = reportRoutes
