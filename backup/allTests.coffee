{FinanceOperation, Factory, Tag} = require('./../src/FinanceOperation/Boot.coffee')
{IncomeService, ExpenseService} = require('./../src/Services.coffee')

balanceTrend = require('./../src/Report/balanceTrend.coffee').balanceTrend
MonthYearRange = require('./../src/Report/balanceTrend.coffee').MonthYearRange
uuid = require 'uuid'
chai = require 'chai'
http = require 'http'
require './../index.coffee'

### 
@TODO: listWithDate 
@TODO: it 'should be able to delete expense and its respective tags', ->
@TODO: it 'should report no entries for monthly expenses for specified month', ->
###

incomeService = new IncomeService()
expenseService = new ExpenseService()

describe 'Income CRUD', ->
  # Create
  it 'should be able to create income', ->
    yearsAgo = new Date(2014, 5, 5)
    income = Factory.income null, 'cad', 10, ['canadian', 'income-tag'], yearsAgo
    incomeService.save income, (saved) ->
      console.log 'saved in `should be able to create income...`'

  # Create
  it 'should be able to create income if it does not already exist (that uses a memorable id for use in updating & deleting testing)', ->
    id = 'memorable-id'
    incomeService.existsWithId id, (exists) ->
      return false if exists is true 
      yearsAgo = new Date(2013, 5, 5)
      income = Factory.income id, 'cad', 10, ['canadian', 'income-tag', 'update', 'delete'], yearsAgo
      incomeService.save income, (saved) -> console.log 'created & saved memorable'
 
  # Retrieve
  it 'should be able to find expense', ->
    expense = Factory.expense null, 'cad', 100000, ['eh']
    expenseService.save expense, (saved) ->
      expenseService.findWithId expense.id, (found) ->
        realExpenseFound = found.body[0]
        comparison = expense.equals(realExpenseFound)
        chai.expect(comparison).to.equal(true)

  # Update
  it 'should be able to update expense', ->
    id = uuid.v4()
    expense = Factory.expense id, 'cad', 100000, ['eh']
    
    # [0] save it    
    expenseService.save expense, (saved) ->
      updatedAmount = 111222333
      expenseUpdate = Factory.expense id, 'aus', updatedAmount, ['eh']
      # [1] update it    
      expenseService.updateWithId expenseUpdate, (updated) ->
        # [2] then find it 
        expenseService.findWithId id, (found) ->      
          # [3] then ensure update persisted
          expenseFoundWithId = found.body[0]
          chai.expect(expenseFoundWithId.money.amount).to.equal(updatedAmount)
 
  # Delete
  it 'should be able to delete expense', ->
    id = uuid.v4()
    expense = Factory.expense id, 'cad', 100000, ['tag0']
    expenseService.save expense, (saved) ->
      expenseService.deleteWithId id, (deleted) ->
        chai.expect(deleted.code).to.equal(200)
        expenseService.findWithId id, (found) -> 
          chai.expect(found.code).to.equal(404)
  
  it 'should be not be able to delete an expense that does not exist', ->
    expense = Factory.expense null, 'cad', 100000, ['tag0']
    expenseService.save expense, (saved) ->
      expenseService.deleteWithId 'id-that-does-not-exist', (deleted) ->
        chai.expect(deleted.code).to.equal(404)


describe 'Expense CRUD', ->
  it 'should be able to create expense', ->
    yearsAgo = new Date(2012, 10, 16)
    expense = Factory.expense null, 'cad', 10, ['eh', 'canadian'], yearsAgo
    expenseService.save expense, (saved) ->
      console.log 'saved in `should be able to create expense...`'

describe 'Reports', ->
  it 'should be able to find between', ->
    expenseService.findBetweenMonths new MonthYearRange(2, 2012, 11, 2015), (results) ->
      # chai.expect(results).to.have.length.of.at.least(1)

describe 'Listing Expenses', ->
 
  ### 
  @TODO: assert that there are no others with the tag & that they all have the tag 
  @TODO: insert data in *specific* time ranges and *specific* tags that can be compared 
  ###
  it 'should be able to list expenses with tag', ->
    tag = 'eh'
    expenseService.listWithTag tag, (found) ->
      chai.expect(found.code).to.equal(302)
      chai.expect(found.body).to.have.length.of.at.least(1)
 
  it 'should not list expenses if there are none with that tag', ->
    tag = 'tag-that-does-not-exist__________'
    expenseService.listWithTag tag, (found) ->
      chai.expect(found.code).to.equal(404)
  
  ############################################

  it 'should be able to list expenses with date', ->
    date = new Date('2015-12-16')
    expenseService.listWithDate date, (found) ->
      chai.expect(found.code).to.equal(302)
      chai.expect(found.body).to.have.length.of.at.least(1)

  it 'should be not list expenses with a date with no entries', ->
    date = new Date('1900-1-15')
    expenseService.listWithDate date, (found) ->
      chai.expect(found.code).to.equal(404)

  ###
  it 'should be not list expenses with an invalid date', ->
    date = new Date('1-20-51')
    expenseService.listWithDate date, (found) ->
      chai.expect(found.code).to.equal(404)
  ###

  it 'should be able to list all expenses', ->
    expenseService.list (found) ->
      chai.expect(found.code).to.equal(302)
      chai.expect(found.body).to.have.length.of.at.least(1)




describe 'Reporting Monthly expenses', ->

  it 'should report monthly expenses for this month', ->
    expenseService.reports null, null, (expenses) -> 
      chai.expect(expenses.code).to.equal 302
      chai.expect(expenses.body).to.be.a 'object'

  it 'should report monthly expenses for specified month', ->
    expenseService.reports 11, 2015, (expenses) -> 
      chai.expect(expenses.code).to.equal 302
      chai.expect(expenses.body).to.be.a 'object'

  it 'should report empty monthly expenses for a month with nothing in it', ->
    expenseService.reports 11, 3000, (expenses) -> 
      chai.expect(expenses.body).to.be.a 'object'

  it 'should should report a balance trend', ->
    balanceTrend incomeService, expenseService, (reports) ->
      chai.expect(reports.code).to.equal 200
      chai.expect(reports.body).to.be.a 'array'
      chai.expect(reports.body).to.have.length.of.at.least 1
      # chai.expect(reports.body[0].month).to.be.a 'int'
      # chai.expect(reports.body[0].year).to.be.a 'int'
      # chai.expect(reports.body[0].income).to.be.a 'int'
      # chai.expect(reports.body[0].expense).to.be.a 'int'
      # chai.expect(reports.body[0].balance).to.be.a 'int'

    , new MonthYearRange(2, 2012, 11, 2015)

