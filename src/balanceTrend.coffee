require 'coffee-script/register'

### 
could also just remove this and improve the query for selecting in the list...
@TODO: refactor to class
@TODO: split up to be more reusable
###
findEarliestAndLatestOfAll = (incomeService, expenseService, cb) ->
  earliestLatest = {}
  # earliest of income
  incomeService.findEarliestDate (incomeEarliest) ->
    # earliest of expense
    expenseService.findEarliestDate (expenseEarliest) ->
      earliestLatest.earliest = if expenseEarliest > incomeEarliest then expenseEarliest else incomeEarliest
      earliestLatest.earliest = new Date(earliestLatest.earliest)
      # latest of income
      incomeService.findLatestDate (incomeLatest) ->
        # latest of expense
        expenseService.findLatestDate (expenseLatest) ->
          earliestLatest.latest = if expenseLatest > incomeLatest then expenseLatest else incomeLatest
          earliestLatest.latest = new Date(earliestLatest.latest)
          cb earliestLatest

### @TODO: remove need for this, optimize query ###
earliestLatestIntoMonthYearRange = (earliestLatest) ->
  earliestMonth = earliestLatest.earliest.getMonth()+1
  earliestYear  = earliestLatest.earliest.getFullYear()
  latestMonth   = earliestLatest.latest.getMonth()+1
  latestYear    = earliestLatest.latest.getFullYear()
  return new MonthYearRange(earliestMonth, earliestYear, latestMonth, latestYear)

balanceTrend = (incomeService, expenseService, cb, monthYearRange) ->
  # there is nothing in it, meaning we do all time
  # so we get earliest and latest in db
  if not monthYearRange?
    findEarliestAndLatestOfAll incomeService, expenseService, (earliestLatest) ->
      monthYearRange = earliestLatestIntoMonthYearRange earliestLatest
      balanceRestOfTrend incomeService, expenseService, cb, monthYearRange
  else 
    balanceRestOfTrend incomeService, expenseService, cb, monthYearRange

balanceRestOfTrend = (incomeService, expenseService, cb, monthYearRange) ->
  rep = new Reporter()
  incomeService.findBetweenMonths monthYearRange, (incomes) ->
    # console.log incomes 
    expenseService.findBetweenMonths monthYearRange, (expenses) ->
      # console.log incomes, expenses
      rep.report(monthYearRange, incomes, expenses)
      cb rep.reports

# could also have Balance object and apply events to it
class Report 
  constructor: (@month, @year, @income, @expense, @balance) ->

### 
@TODO: use moment-range.js npm
@TODO: use a chaining singleton for construction, @example MonthYearRange.startMonth(return @).startYear()...
###
class MonthYearRange 
  constructor: (@startMonth = 1, @startYear = 1900, @endMonth = 12, @endYear = 2015) ->
  toString: -> JSON.stringify({startMonth: @startMonth; startYear: @startYear; endMonth: @endMonth; endYear: @endYear})

### @TODO: refactor and model the concepts ###
class Reporter
  constructor: (@balance = 0, @reports = []) ->

  report: (monthYearRange, incomes, expenses) ->
    moment = require 'moment'
    if Array.isArray(incomes)
      incomes = incomes.map (item) -> item.created_at = moment(item.created_at); return item
    if Array.isArray(expenses)
      expenses = expenses.map (item) -> item.created_at = moment(item.created_at); return item

    startYear = monthYearRange.startYear
    endYear = monthYearRange.endYear
    startMonth = monthYearRange.startMonth
    endMonth = monthYearRange.endMonth

    # going through each year
    for year in [startYear .. endYear]
      # each month of the year
      for month in [0 .. 12]
        # if the start, ensure month is higher or same
        if year is startYear and month < startMonth
          continue # if not month >= startMonth
        # if the end, ensure month is lower or same
        if year is endYear and month > endMonth
          continue 
        
        yearAndMonthFilter = (item) ->
          return true if item.created_at.year() is year and item.created_at.month() is month
          return false 

        # because if not found
        if Array.isArray(incomes)
          monthIncomes = incomes.filter yearAndMonthFilter
        else 
          monthIncomes = []
        
        # because if not found
        if Array.isArray(expenses)
          monthExpenses = expenses.filter yearAndMonthFilter
        else 
          monthExpenses = []

        ### 
        @TODO currency conversion & optimize with next if + chain
        if there is something in them, we filter
        otherwise, they are empty/worthless/0
        ###
          
        if monthIncomes.length is 0
          monthIncomes = 0 
        else
          monthIncomes = monthIncomes.map (item) -> item.money.amount
          monthIncomes = monthIncomes.reduce (a, b) -> a+b

        if monthExpenses.length is 0
          monthExpenses = 0 
        else
          monthExpenses = monthExpenses.map (item) -> item.money.amount
          monthExpenses = monthExpenses.reduce (a, b) -> a+b

        calculated = (monthIncomes - monthExpenses)
        @balance += calculated
        @reports.push new Report(month, year, monthIncomes, monthExpenses, @balance)

module.exports.MonthYearRange = MonthYearRange
module.exports.balanceTrend = balanceTrend
module.exports.Report = Report