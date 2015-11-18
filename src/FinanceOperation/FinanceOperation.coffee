_ = require 'underscore'
uuid = require 'uuid'
{dateFromAny} = require('./../Util/dateFrom.coffee')
{Tag} = require('./Tag.coffee')

class FinanceOperation
  ### 
  @TODO: Validate types
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
    if _.isArray @tags
      for i in [0 .. @tags.length-1]
        return true if tagName is @tags[i].name
      return false
    return if (@tags.name is tagName) then true else false 
 
  tagsAsString: ->
    tags = ''
    for tag in @tags
      tags += tag.name + ',' 
    return tags.substring(0, tags.length - 1) # trim the trailing comma
    
  ###
  toString: ->
    id: @id
    money: @money 
    created_at: @created_at
    description: @description 
    tags: @tagsAsString()
  ###
  # tagsAsArray: ->


### @desc tracks spendings ###
class Expense extends FinanceOperation

### @desc tracks earnings ###
class Income extends FinanceOperation

module.exports.Expense = Expense
module.exports.Income = Income
module.exports.FinanceOperation = FinanceOperation
