# could also have Balance object and apply events to it
class Report 
  constructor: (@month, @year, @income, @expense, @balance) ->

module.exports.Report = Report
