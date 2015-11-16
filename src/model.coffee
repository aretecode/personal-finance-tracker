require 'coffee-script/register'
_ = require 'underscore'
uuid = require 'uuid'

###
@TODO: use these to validate
http://openexchangerates.org/currencies.json
###

class AbstractFinanceOperationFactory 
  ### 
  @see {Money}
  @see {Income}
  @see {Expense}
  @TODO: if this fails, give back a payload http status code
  @TODO: add a constructor + chaining builder
  ###
  @createFrom: (opType, id, currency, amount, tags, createdAt = new Date(), description = "") =>
    id = uuid.v4() if id is null 
    money = new Money(currency, amount)
    if opType is 'income'
      return new Income(id, money, tags, createdAt, description) 
    else if opType is 'expense'
      return new Expense(id, money, tags, createdAt, description) 

  @hydrateFrom: (opType, o, tags) ->
    createdAt = new Date(o.created_at)
    return AbstractFinanceOperationFactory.createFrom(opType, o.id, o.currency, o.amount, tags, createdAt, o.description)

  @hydrateAllFrom: (opType, objs, tags) ->
    financialObjs = []
    for i in [0 .. objs.length-1]
      o = objs[i]
      createdAt = new Date(o.created_at)
      financialObjs.push AbstractFinanceOperationFactory.createFrom(opType, o.id, o.currency, o.amount, tags, createdAt, o.description)

    return financialObjs

  @income: (id, currency, amount, tags, createdAt = new Date, description = "") ->
    # if it is not a date and it is a string, we make it into a Date
    createdAt = new Date(createdAt) if not createdAt instanceof Date 
    id = uuid.v4() if id is null or id is undefined
    money = new Money(currency, amount)
    return new Income(id, money, tags, createdAt, description) 
  @expense: (id, currency, amount, tags, createdAt = new Date, description = "") ->
    createdAt = new Date(createdAt) if not createdAt instanceof Date 
    id = uuid.v4() if id is null or id is undefined
    money = new Money(currency, amount)
    return new Expense(id, money, tags, createdAt, description) 

# could be a collection here and reference that id
# it could be enforced that lowercase is passed in 
# we could enforce a character range 
class Tag 
  # id 
  name: ""

  # Invariant: name is always lowercase
  constructor: (aName) ->
    @name = aName.toLowerCase()

  toString: -> @name 

  # @TODO: if !string&!arr, error
  # if it has a comma, explode it, make them into an array of Tags
  @tagsFrom: (tags) ->    
    if Array.isArray tags 
      return Tag.uniqueAndMakeList(tags)

    if tags.indexOf(',') > -1 
      stringTags = tags.split(',')
      return Tag.uniqueAndMakeList(stringTags)

    return new Tag(tags)

  @uniqueAndMakeList: (tags) ->
    tags = _.uniq tags

    tagArray = []
    for i in [0 .. tags.length-1]
      tagArray.push new Tag(tags[i])

    tagArray


class Money 
  ### 
  @TODO: Can assert the types
  @TODO: Pass in a single tag - currently assuming it is always an array

  @param {string|Currency} currency - must be valid in Currencies
  @param {int} amount       
  ###
  constructor: (@currency, @amount) ->
 
  ### @type{Money} ###
  equals: (money) ->
    return true if money.currency is @currency and money.amount is @amount
    return false

class FinanceOperation
  ### 
  @TODO: Can assert the types
  @TODO: Pass in a single tag - currently assuming it is always an array

  @param {Money}      money
  @param {array<Tag>} tags        1+
  @param {Timestamp}  created_at  (optional) default: now
  @param {String}     description (optional)
  ###
  constructor: (@id, @money, tags, @created_at = new Date, @description = "") ->
    @tags = Tag.tagsFrom tags

  ###
  @param FinanceOperation or child
  @TODO: could return what is false 
  ###
  equals: (finance) ->
    return false if not finance.money.equals(@money) 
    return false if not finance.tags is @tags
    return false if not finance.created_at is @created_at
    return false if not finance.description is @description
    return true

  hasTag: (tagName) ->
    if Array.isArray @tags
      for i in [0 .. @tags.length-1]
        return true if tagName is @tags[i].name
      return false
    return if (@tags.name is tagName) then true else false 

### @desc tracks spendings ###
class Expense extends FinanceOperation

### @desc tracks earnings ###
class Income extends FinanceOperation

module.exports.Income = Income
module.exports.Expense = Expense
module.exports.FinanceOperation = FinanceOperation
module.exports.AbstractFinanceOperationFactory = AbstractFinanceOperationFactory
module.exports.Money = Money
module.exports.Tag = Tag