require 'coffee-script/register'

balanceTrend = (incomeService, expenseService, cb, monthYearRange = new MonthYearRange(2, 2012, 11, 2015)) ->
  rep = new Reporter()
  incomes = incomeService.findBetweenMonths monthYearRange, (incomes) ->
    expenses = expenseService.findBetweenMonths monthYearRange, (expenses) ->
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

        if Array.isArray(incomes)
          monthIncomes = incomes.filter yearAndMonthFilter
        else 
          monthIncomes = []
     
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
          monthIncomes = 0 #if monthIncomes.length is 0 
        else
          monthIncomes = monthIncomes.map (item) -> item.amount
          monthIncomes = monthIncomes.reduce (a, b) -> a+b

        if monthExpenses.length is 0
          monthExpenses = 0 
        else
          monthExpenses = monthExpenses.map (item) -> item.amount
          monthExpenses = monthExpenses.reduce (a, b) -> a+b

        calculated = (monthIncomes - monthExpenses)
        @balance += calculated
        @reports.push new Report(month, year, monthIncomes, monthExpenses, @balance)

module.exports.MonthYearRange = MonthYearRange
module.exports.balanceTrend = balanceTrend
module.exports.Report = Report