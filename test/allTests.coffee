require 'coffee-script/register'

{Expense, Income, FinanceOperation, AbstractFinanceOperationFactory, Money, Tag} = require('./../src/model.coffee')
{FinanceService, IncomeService, ExpenseService, IncomeRepository, ExpenseRepository} = require('./../src/db.coffee')
balanceTrend = require('./../src/balanceTrend.coffee').balanceTrend
MonthYearRange = require('./../src/balanceTrend.coffee').MonthYearRange
uuid = require 'uuid'
chai = require 'chai'

### 
@TODO: listWithDate 
@TODO: it 'should be able to delete expense and its respective tags', ->
@TODO: it 'should report no entries for monthly expenses for specified month', ->
###

incomeService = new IncomeService()
expenseService = new ExpenseService()

### @TODO: MOVE OUT OF TESTS ###
createFinancialOperation = (pg, name) ->
  pg.schema.createTableIfNotExists name, (table) ->
    ### @TODO: should change to uuid ###
    table.string('id').primary()
    table.string('currency').notNullable()
    table.integer('amount').notNullable()
    table.timestamp('created_at') # .defaultTo(pg.fn.now())
    table.string('description').nullable().defaultTo(null)
  .then (what) ->
    console.log "created"
    console.log what 

createTags = (pg) ->
  pg.schema.createTableIfNotExists 'tags', (table) ->
    ### @TODO: should change to uuid ###
    table.string('id')
    table.string('tag').notNullable()
    table.primary(['id', 'tag'])
  .then (what) ->
    console.log "created tags"
    console.log what 

describe 'Db', ->
  pg = require('./../src/connection.coffee').getPg()

  it 'should create income', ->
    pg.schema.hasTable('income').then (exists) ->
      createFinancialOperation(pg, 'income') if not exists

  it 'should create expense', ->
    pg.schema.hasTable('expense').then (exists) ->
      createFinancialOperation(pg, 'expense') if not exists
 
  it 'should create tags', ->
    pg.schema.hasTable('tags').then (exists) ->
      createTags(pg) if not exists

  it 'should have tables in the postgres', ->
    pg.schema.hasTable('tags').then (exists) ->
      chai.expect(exists).to.equal(true)
    pg.schema.hasTable('income').then (exists) ->
      chai.expect(exists).to.equal(true)
    pg.schema.hasTable('expense').then (exists) ->
      chai.expect(exists).to.equal(true)


describe 'API', ->
  it 'should be able to create income', ->
    yearsAgo = new Date(2014, 5, 5)
    income = AbstractFinanceOperationFactory.income null, 'cad', 10, ['canadian', 'income-tag'], yearsAgo
    incomeService.save income, (saved) ->
      console.log 'saved in `should be able to create income...`'

  ### @TODO: insert only if not created ###
  it 'should be able to create income (that uses a memorable id for use in updating & deleting testing)', ->
    id = 'memorable-id'
    incomeService.existsWithId id, (exists) ->
      return false if exists is true 

      yearsAgo = new Date(2013, 5, 5)
      income = AbstractFinanceOperationFactory.income id, 'cad', 10, ['canadian', 'income-tag', 'update', 'delete'], yearsAgo
      incomeService.save income, (saved) -> console.log 'created & saved memorable'
      
  it 'should be able to create expense', ->
    yearsAgo = new Date(2012, 10, 16)
    expense = AbstractFinanceOperationFactory.expense null, 'cad', 10, ['eh', 'canadian'], yearsAgo
    expenseService.save expense, (saved) ->
      console.log 'saved in `should be able to create expense...`'

  it 'should be able to find between', ->
    expenseService.findBetweenMonths new MonthYearRange(2, 2012, 11, 2015), (results) ->
      # chai.expect(results).to.have.length.of.at.least(1)

  it 'should be able to find expense', ->
    expense = AbstractFinanceOperationFactory.expense null, 'cad', 100000, ['eh']
    expenseService.save expense, (saved) ->
      expenseService.findWithId expense.id, (found) ->
        realExpenseFound = found[0]
        comparison = expense.equals(realExpenseFound)
        chai.expect(comparison).to.equal(true)

  it 'should be able to delete expense', ->
    expense = AbstractFinanceOperationFactory.expense null, 'cad', 100000, ['tag0']
    ### @TODO: fetch it out again to make sure it is not there ###
    expenseService.save expense, (saved) ->
      expenseService.deleteWithId expense.id, (deleted) ->
        console.log "deleted!!", deleted

  it 'should be able to update expense', ->
    id = uuid.v4()
    expense = AbstractFinanceOperationFactory.expense id, 'cad', 100000, ['eh']
    
    # [0] save it    
    expenseService.save expense, (saved) ->
      updatedAmount = 111222333
      expenseUpdate = AbstractFinanceOperationFactory.expense id, 'aus', updatedAmount, ['eh']
      # [1] update it    
      expenseService.updateWithId expenseUpdate, (updated) ->
        # [2] then find it 
        expenseService.findWithId id, (found) ->      
          # [3] then ensure update persisted
          expenseFoundWithId = found[0]
          chai.expect(expenseFoundWithId.money.amount).to.equal(updatedAmount)

    return null
 
  ### 
  @TODO: assert that there are no others with the tag & that they all have the tag 
  @TODO: insert data in *specific* time ranges and *specific* tags that can be compared 
  ###
  it 'should be able to list expenses with tag', ->
    tag = 'eh'
    expenseService.listWithTag tag, (found) ->
      chai.expect(found).to.have.length.of.at.least(1)
  
  # list by date, list by tag
  it 'should list all expenses', ->
    expenseService.list (list) -> console.log 'should list all expenses: ', list.length

  it 'should report monthly expenses for this month', ->
    expenseService.reports null, null, (expenses) -> console.log "expenses :-)", expenses.length
        
  it 'should report monthly expenses for specified month', ->
    expenseService.reports 1, 2015, (expenses) -> console.log expenses.length

  it 'should should report a balance trend', ->
    balanceTrend incomeService, expenseService, (reports) ->
      console.log 'reports (default range): ', reports.length
      chai.expect(reports).to.have.length.of.at.least(1)
    , new MonthYearRange(2, 2012, 11, 2015)

describe 'Factory', ->
  it 'should create an instance of Income the same as making it manually', ->
    now = new Date()
    id = uuid.v4()
    incomeFromFactory = AbstractFinanceOperationFactory.income(id, 'cad', 100000, ['eh'], now)
    money = new Money('cad', 100000)
    incomeFromManual = new Income(id, money, ['eh'], now)

    incomeEqual = incomeFromFactory.equals(incomeFromManual)
    chai.expect(incomeEqual).to.equal(true)

describe 'Tag', ->
  it 'should have a lowercase name', ->
    ucString = 'Meta'
    lcString = ucString.toLowerCase()
    tag = new Tag(ucString)

    chai.expect(tag.name).to.equal(lcString)

describe 'Operations', ->
  it 'should have unique tags', ->
    id = uuid.v4()
    incomeFromFactory = AbstractFinanceOperationFactory.income id, 'cad', 100000, ['tag0', 'tag1', 'tag1']
    expected = [new Tag('tag0'), new Tag('tag1')]
    chai.expect(incomeFromFactory.tags[0].toString()).to.equal(expected[0].toString())
    chai.expect(incomeFromFactory.tags[1].toString()).to.equal(expected[1].toString())
