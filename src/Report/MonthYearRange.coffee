### 
@TODO: use moment-range.js npm
@TODO: use a chaining singleton for construction, @example MonthYearRange.startMonth(return @).startYear()...
###
class MonthYearRange 
  constructor: (@startMonth = 1, @startYear = 1900, @endMonth = 12, @endYear = 2015) ->
  toString: -> JSON.stringify({startMonth: @startMonth; startYear: @startYear; endMonth: @endMonth; endYear: @endYear})

module.exports.MonthYearRange = MonthYearRange
