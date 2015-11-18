_ = require 'underscore'
uuid = require 'uuid'
{dateFromAny} = require('./../Util/dateFrom.coffee')
{Money} = require('./Money.coffee')
{Tag} = require('./Tag.coffee')
Income = require('./FinanceOperation.coffee').Income
Expense = require('./FinanceOperation.coffee').Expense

class AbstractFinanceOperationFactory 
  ### 
  @see {Money}
  @see {Income}
  @see {Expense}
  @TODO: if this fails, give back a payload http status code
  @TODO: add a constructor + chaining builder
  ###
  @createFrom: (opType, id, currency, amount, tags, createdAt = new Date(), description = "") =>
    c = dateFromAny(createdAt)
    id = uuid.v4() if id is null or id is undefined
    money = new Money(currency, amount)
    if opType is 'income'
      return new Income(id, money, tags, createdAt, description) 
    else if opType is 'expense'
      return new Expense(id, money, tags, createdAt, description) 

  @hydrateFrom: (opType, o, tags) ->
    c = new Date(o.created_at)
    return AbstractFinanceOperationFactory.createFrom(
      opType, o.id, o.currency, o.amount, tags, c, o.description)

  @hydrateAllFrom: (opType, objs, tags) ->
    financialObjs = []
    for i in [0 .. objs.length-1]
      o = objs[i]
      c = new Date(o.created_at)
      financialObjs.push AbstractFinanceOperationFactory.createFrom(opType, o.id, o.currency, o.amount, tags, c, o.description)

    return financialObjs

  @income: (id, currency, amount, tags, createdAt = new Date, description = "") ->
    return AbstractFinanceOperationFactory.createFrom('income', id, currency, amount, tags, createdAt, description)
  @expense: (id, currency, amount, tags, createdAt = new Date, description = "") ->
    return AbstractFinanceOperationFactory.createFrom('expense', id, currency, amount, tags, createdAt, description)

module.exports.AbstractFinanceOperationFactory = AbstractFinanceOperationFactory
