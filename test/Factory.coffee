uuid = require 'uuid'
chai = require 'chai'

{Income, Money, Factory} = require('./../src/FinanceOperation/Boot.coffee')

describe 'Factory', ->
  it 'should create an instance of Income the same as making it manually', ->
    now = new Date()
    id = uuid.v4()
    incomeFromFactory = Factory.income(id, 'cad', 100000, ['eh'], now)
    money = new Money('cad', 100000)
    incomeFromManual = new Income(id, money, ['eh'], now)

    incomeEqual = incomeFromFactory.equals(incomeFromManual)
    chai.expect(incomeEqual).to.equal(true)
