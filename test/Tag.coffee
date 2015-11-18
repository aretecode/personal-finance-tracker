{Tag, Factory} = require('./../src/FinanceOperation/Boot.coffee')
uuid = require 'uuid'
chai = require 'chai'

describe 'Tag', ->
  it 'should have a lowercase name', ->
    ucString = 'Meta'
    lcString = ucString.toLowerCase()
    tag = new Tag(ucString)
    chai.expect(tag.name).to.equal(lcString)
    
  it 'should have unique tags', ->
    id = uuid.v4()
    incomeFromFactory = Factory.income id, 'cad', 100000, ['tag0', 'tag1', 'tag1']
    expected = [new Tag('tag0'), new Tag('tag1')]
    chai.expect(incomeFromFactory.tags[0].toString()).to.equal(expected[0].toString())
    chai.expect(incomeFromFactory.tags[1].toString()).to.equal(expected[1].toString())
