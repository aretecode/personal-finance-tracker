{_} = require 'underscore'
{Payload} = require('./Payload.coffee')
{dateFromAny} = require('./Util/dateFrom.coffee')
{FinanceRepository} = require('./Persistence/Repository.coffee') 

# could find how to use a DIC in nodejs  
# using methods on here for our service enables easy spot for adding caching
# Abstract
class FinanceService 
  constructor: (@repo) ->

  save: (finance, callback) ->    
    repo = @repo
    @repo.existsWithId finance.id, (exists) ->
      if exists is true 
        callback new Payload(409, 'already exists')
      else 
        repo.save finance, (result) ->
          count = result.rowCount 
          code = if count is 0 then 500 else 201
          callback new Payload(code, count)
  
  find: (id, callback) -> @findWithId id, callback
  findWithId: (id, callback) -> 
    @repo.findWithId id, (result) ->
      code = if result.length is 0 then 404 else 302
      callback new Payload(code, result)
  
  delete: (id, callback, tagsCb) -> @deleteWithId id, callback, tagsCb
  deleteWithId: (id, callback, tagsCb) -> 
    @repo.deleteWithId id, (result) ->
      code = if result is 0 then 404 else 200
      callback new Payload(code, id)
  
  update: (finance, callback) -> @updateWithId finance, callback
  updateWithId: (finance, callback) -> 
    @repo.updateWithId finance, (result) ->
      code = if result is 0 then 400 else 200
      callback new Payload(code, finance)

  listWithTag: (tag, callback) -> 
    @repo.listWithTag tag, (result) ->
      code = if result.length is 0 then 404 else 302
      callback new Payload(code, result)
 
  listWithDate: (date, callback) -> 
    date = dateFromAny(date)
    table = @repo.table
    @repo.listWithDate date, (result) ->
      code = if result.length is 0 then 404 else 302
      if code is 404
        message = table + ' listing not found for month: `' + date.getMonth() + '` and year: `' + date.getFullYear() + '`'
        callback new Payload(code, message)
      else
        callback new Payload(code, result)

  list: (callback) -> 
    @repo.list (result) ->
      code = if result.length is 0 then 404 else 302
      callback new Payload(code, result)

  findBetweenMonths: (monthYearRange, callback) -> @repo.findBetweenMonths monthYearRange, callback

  existsWithId: (id, callback) -> @repo.existsWithId id, callback
  findEarliestDate: (callback) -> @repo.findEarliestDate callback
  findLatestDate: (callback) -> @repo.findLatestDate callback

  ### 
  if year & month are not defined, set the *current* month and date
  @TODO: combine this with list and add the params with a default of 'infinity' for type? 
  @TODO: remove these defaults and make service skinnier

  @param {string|int: month} month 
  @param {string|int: month} int 
  @param {function} callback 
  ###
  reports: (month, year, callback) ->
    year = new Date().getFullYear() if not year?
    month = new Date().getMonth()+1 if not month? # +1
    console.log month, year
    table = @repo.table
    @repo.findWithMonthYear month, year, (result) ->
      code = if (result.length is 0) then 404 else 302
      if code is 404
        message = table + ' reporting not found for month: `' + date.getMonth() + '` and year: `' + date.getFullYear() + '`'
      else 
        message = ''
      callback new Payload(code, result, message)

  createIfUnique: (finance, callback) ->
    repo = @repo
    @repo.existsWithId finance.id, (exists) ->
      if exists 
        return callback new Payload(409, 'already exists')

      repo.save finance, (result) ->
        count = result.rowCount 
        code = if count is 0 then 500 else 201
        callback new Payload(code, count)

class IncomeService extends FinanceService
  constructor: (@repo = new FinanceRepository('income')) ->

class ExpenseService extends FinanceService
  constructor: (@repo = new FinanceRepository('expense')) ->

module.exports.ExpenseService = ExpenseService
module.exports.IncomeService = IncomeService