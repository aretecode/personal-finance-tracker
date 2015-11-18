_ = require 'underscore'

dateFrom = (date) ->
  if date instanceof Date    
    return date
  else if _.isString(date) and date.includes('-')
    date = new Date(date)
  else if not _.isNaN(parseInt(date))
    date = new Date(parseInt(date))
  else if _.isString date
    date = new Date(date)
  else if not date instanceof Date    
    date = new Date(date)
  return date 

module.exports.dateFromAny = dateFrom