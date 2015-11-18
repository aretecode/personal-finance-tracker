###
@TODO: use these to validate
http://openexchangerates.org/currencies.json
###

class Money 
  ### 
  @TODO: Can assert the types
  @param {string|Currency} currency - must be valid in Currencies
  @param {int} amount       
  ###
  constructor: (@currency, @amount) ->
 
  ### @type{Money} ###
  equals: (money) ->
    if money.currency is @currency and money.amount is @amount 
      return true 
    return false

module.exports.Money = Money
