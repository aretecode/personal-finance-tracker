{FinanceOperation, Factory, Tag} = require('./../src/FinanceOperation/Boot.coffee')
{IncomeService, ExpenseService} = require('./../src/Services.coffee')

{dateFromAny} = require('./../src/Util/dateFrom.coffee')
{MonthYearRange} = require('./../src/Report/balanceTrend.coffee')
uuid = require 'uuid'
chai = require 'chai'
http = require 'http'
require './../index.coffee'

incomeService = new IncomeService()
expenseService = new ExpenseService()

financeAsRequest = (f, name) ->
  return ('/api/' + name + '/' + f.money.currency + '/' + f.money.amount + '/' + f.tagsAsString() + '/' + f.created_at + '/' + f.description + '/' + f.id)

financeAsUpdate = (f, name) ->
  return ('/api/' + name + '/' + f.id + '/' + f.money.currency + '/' + f.money.amount + '/' + f.tagsAsString() + '/' + f.created_at.getTime() + '/' + f.description)

getResult = (res, callback) ->
  data = ''
  res.on 'data', (chunk) ->
    data += chunk
  res.on 'end', ->
    callback data

# Test Data
incomes = []
expenses = []
incomes.push Factory.income null, 'cad', 10, ['canadian', 'unique-tag-group'], new Date(2000, 5, 5)
incomes.push Factory.income null, 'cad', 10, ['canadian'], new Date(2001, 5, 5)
incomes.push Factory.income null, 'cad', 5, ['eh']
incomes.push Factory.income null, 'cad', 15, ['eh']
expenses.push Factory.expense null, 'cad', 5, ['canadian']
expenses.push Factory.expense null, 'cad', 5, ['canadian', 'unique-tag-group'], new Date(2001, 5, 5)
expenses.push Factory.expense null, 'cad', 15, ['eh']
expenses.push Factory.expense null, 'cad', 10, ['eh']

# could put this + delete in a before() & after()
# save with financeAsRequest
describe 'Income CRUD', ->
    
  # nest saving these 4
  before (done) ->
    id = 'memorable-id'
    incomeService.existsWithId id, (exists) ->
      return false if exists is true 
      yearsAgo = new Date(2013, 5, 5)
      income = Factory.income id, 'cad', 10, ['canadian', 'income-tag', 'update', 'delete'], yearsAgo
      incomeService.save income, (saved) -> console.log 'created & saved memorable'

    expenseService.save expenses[0], (saved) -> chai.expect(saved.code).to.equal(201)
    expenseService.save expenses[1], (saved) -> 
    expenseService.save expenses[2], (saved) -> 
    expenseService.save expenses[3], (saved) -> 
      chai.expect(saved.code).to.equal(201)
      incomeService.save incomes[0], (saved) -> chai.expect(saved.code).to.equal(201)
      incomeService.save incomes[1], (saved) -> chai.expect(saved.code).to.equal(201)
      incomeService.save incomes[2], (saved) -> chai.expect(saved.code).to.equal(201)
      incomeService.save incomes[3], (saved) -> 
        chai.expect(saved.code).to.equal(201)
        done()
  after (done) ->
    for expense in expenses
      expenseService.delete expense.id, (deleted) -> chai.expect(deleted.code).to.equal(200)
    for income in incomes
      incomeService.delete income.id, (deleted) -> chai.expect(deleted.code).to.equal(200)
    done()

  # Create
  it 'should be able to create income', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/cad/10/canadian,eh'
      method: 'PUT'
  
    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.equal 1          
        chai.expect(res.statusCode).to.equal 201        
        done()
      req.end()
    catch e 
      done e 
 

  # Retrieve
  it 'should be able to find income', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/retrieve/memorable-id' # + expenses[0].id
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'
  
    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.equal 1     
          comparison = expenses[0].equals(data.body[0])
          chai.expect(comparison).to.equal(true)

        chai.expect(res.statusCode).to.equal 302        

        done()
      req.end()
    catch e 
      done e


  # Update
  it 'should be able to update income', (done) ->
    incomes[0].money.currency = 'aus'
    incomes[0].money.amount = 20
  
    path = financeAsUpdate(incomes[0], 'incomes')

    options = 
      hostname: 'localhost'
      port: '5000'
      path: path
      method: 'PATCH'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.equal 1     
          comparison = expenses[0].equals(data.body[0])
          chai.expect(comparison).to.equal(true)

        chai.expect(res.statusCode).to.equal 200        

        done()
      req.end()
    catch e 
      done e


  # Delete
  it 'should be able to delete income', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/memorable-id'# + incomes[0].id
      method: 'DELETE'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          #chai.expect(data).to.equal id         

        chai.expect(res.statusCode).to.equal 200        
        done()
      req.end()
    catch e 
      done e



  it 'should be able to list income', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/list'
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'
    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1 
        
        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e 
      done e



  it 'should be able to list income with tag', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/list/?tag=unique-tag-group'
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of 1 

        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e 
      done e
 


  it 'should be able to list income with date', (done) ->
    path = '/api/incomes/list/?date=' + new Date().getTime()
    options = 
      hostname: 'localhost'
      port: '5000'
      path: path
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->  
          chai.expect(data).to.have.length.of.at.least 1 
        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e         
      done e
 
  it 'should be able to list income with date from string', (done) ->
    date = new Date()
    month = date.getMonth()+1
    year = date.getFullYear()
    day = date.getDay()
    dateString = year + '-' + month + '-' + day

    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/incomes/list/?date=' + dateString
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1 
        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e         
      done e


  it 'should should report a balance trend for all time by default', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/reports/balance/trend'
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1
          chai.expect(data).to.be.a 'array'

        chai.expect(res.statusCode).to.equal 200        
        done()
      req.end()
    catch e         
      done e
 

  it 'should should report a balance trend for specified range', (done) ->
    options = 
      hostname: 'localhost'
      port: '5000'
      path: '/api/reports/balance/trend/2-2012,12-2015'
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1
          chai.expect(data).to.be.a 'array'

        chai.expect(res.statusCode).to.equal 200        
        done()
      req.end()
    catch e         
      done e



  it 'should report empty monthly incomes for a month with nothing in it', (done) ->
    path = '/api/reports/incomes/monthly/'+1+'/'+3000
    options = 
      hostname: 'localhost'
      port: '5000'
      path: path
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of 0
          chai.expect(data).to.be.a 'object'

        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e         
      done e

  it 'should report monthly incomes for this month', (done) ->
    path = '/api/reports/incomes/monthly'
    options = 
      hostname: 'localhost'
      port: '5000'
      path: path
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1 
          chai.expect(data).to.be.a 'object'

        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e         
      done e


  it 'should report monthly incomes for specified month', (done) ->
    thisMonth = new Date().getMonth()+1
    thisYear = new Date().getFullYear()
    path = '/api/reports/incomes/monthly/'+thisMonth+'/'+thisYear
    options = 
      hostname: 'localhost'
      port: '5000'
      path: path
      method: 'GET'
      headers:
        'Authorization': 'Bearer 123456789'

    try 
      req = http.request options, (res) ->
        getResult res, (data) ->
          chai.expect(data).to.have.length.of.at.least 1 
          chai.expect(data).to.be.a 'object'

        chai.expect(res.statusCode).to.equal 302        
        done()
      req.end()
    catch e         
      done e
