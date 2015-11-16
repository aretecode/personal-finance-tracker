require 'coffee-script/register'
_ = require 'underscore'
{Expense, Income, FinanceOperation, AbstractFinanceOperationFactory, Money, Tag} = require('./../src/model.coffee')
Factory = AbstractFinanceOperationFactory
MonthYearRange = require('./balanceTrend.coffee').MonthYearRange

### @TODO: find with tag in range ###
class FinanceRepository 
  constructor: () -> @pg = require('./connection.coffee').getPg()

  ### 
  # @TODO: json encode or obj props as @params?
  # insert or create
  #
  # @param {FinanceOption} financeOption or any children (Income or Expense)
  ###
  save: (financeOption, cb) ->    
    data = 
      id: financeOption.id
      # Money, could be split into another table
      currency: financeOption.money.currency
      amount: financeOption.money.amount
      # optional
      created_at: financeOption.created_at
      description: financeOption.description
    
    ### 
    @TODO: send back a better response, including tags if needed
    @TODO: ensure it was not already added, differently than tags... 
    ###
    @pg
    .insert(data)
    .into(@table).then (rows) -> cb data.id; 

    ### @TODO: return a Payload for if it already exists ###
    ### @TODO: optimize & combine the query ###
    tags = financeOption.tags
    if Array.isArray tags
      for i in [0 .. tags.length-1]
        tag = 
          tag: tags[i].name
          id: data.id
        @saveTag(tag)
    else
      tag = 
        tag: tags.name
        id: data.id
      @saveTag(tag)

  ### 
  @param {{id: string, tag: string}} 
  @TODO: fix with the callback
  ###
  saveTag: (tag, cb) ->
    @pg
    .insert(tag)
    .into('tags')
    .whereNotExists( -> 
      @select(@pg.raw(1)).from('tags').where('id', '=', tag.id).andWhere('tag', '=', tag.tag)
    )
    .then ((tag) -> console.log "then" )
    .catch ((e) -> console.log "catch" )

  findWithId: (id, cb) ->
    {pg, table} = {@pg, @table}
    @pg.select().from(@table).where('id', '=', id).then (rows) ->  
      pg.select('tag').from('tags').where('id', '=', id).then (tags) -> 
        tags = _.map tags, (tag) -> tag = tag.tag
        try 
          found = Factory.hydrateAllFrom table, rows, tags
          cb found
        catch e
          cb {error: 404; message: table + ' not found with id: `' + id + '` '}

  findCreatedAtSortedBy: (sorted, cb) ->
    @pg.select('created_at').from(@table).limit(1).orderBy('created_at', sorted)
    .then (row) -> 
      cb row[0].created_at

  findEarliestDate: (cb) -> @findCreatedAtSortedBy('asc', cb)
  findLatestDate: (cb) -> @findCreatedAtSortedBy('desc', cb)

  findBetweenMonths: (monthYearRange = new MonthYearRange(), cb) ->
    query = @pg(@table).select()
    .whereRaw("EXTRACT(YEAR FROM created_at) >= " + monthYearRange.startYear)
    .andWhereRaw("EXTRACT(YEAR FROM created_at) <= " + monthYearRange.endYear)
    .andWhereRaw("EXTRACT(MONTH FROM created_at) >= " + monthYearRange.startMonth)
    .andWhereRaw("EXTRACT(MONTH FROM created_at) <= " + monthYearRange.endMonth)
    .toString()

    {pg, table} = {@pg, @table}
    @pg.raw(query).then (all) -> return all.rows
    .map (item) ->
      pg.select('tag').from('tags').where('id', '=', item.id).then (tagRow) ->
        # because not all tags are in all tables
        return null if tagRow.length is 0 

        ### @TODO: move this into the hydrator ###
        tags = ''
        for i in [0 .. tagRow.length-1]
          tags += tagRow[i].tag + ',' 
        tags = tags.substring(0, tags.length - 1) # trim the trailing comma

        return Factory.hydrateFrom table, item, tags
    .then (all) ->
      all = _.flatten(all)
      cb all 

  ###
  @TODO: optimize query, combine extract?
  prev:  findWhereMonth
  @TODO: @param enforce type int
  ###
  findWithMonthYear: (month, year, cb) ->
    query = @pg(@table).select().whereRaw("EXTRACT(MONTH FROM created_at) = " + month).andWhereRaw("EXTRACT(YEAR FROM created_at) = " + year).toString()

    {pg, table} = {@pg, @table}
    @pg.raw(query).then (all) -> return all.rows
    .map (item) ->
      pg.select('tag').from('tags').where('id', '=', item.id).then (tagRow) ->
        # because not all tags are in all tables
        return null if tagRow.length is 0 

        ### @TODO: move this into the hydrator ###
        tags = ''
        for i in [0 .. tagRow.length-1]
          tags += tagRow[i].tag + ',' 
        tags = tags.substring(0, tags.length - 1) # trim the trailing comma

        return Factory.hydrateFrom table, item, tags
    .then (all) ->
      all = _.flatten(all)

      ### @TODO: optimize, don't need to loop 2x ###
      tags = {}

      # getting all the tags from all the items
      for i in [0 .. all.length-1]
        tag = all[i].tags
        if Array.isArray tag
          for ii in [0 .. tag.length-1]
            tags[tag[ii].name] = 0
        else 
          tags[tag.name] = 0
      
      # go through all tags 
      # and get items that correspond
      for tag, value of tags
        for i in [0 .. all.length-1]
          # add the income or expense to the tag 
          tags[tag] += all[i].money.amount if all[i].hasTag(tag)
      # send the tags to the callback
      cb tags 

  existsWithId: (id, cb) ->
    @pg.select('id').from(@table).where('id', '=', id).then (rows) ->  
      if rows.length is 0
        cb false
      else 
        cb true

  findWithTag: (tag, cb) ->
    {pg, table} = {@pg, @table}
    @pg.select('id', 'tag').from('tags').where('tag', '=', tag).then (tagResult) ->
      tagResult = tagResult[0] if Array.isArray tagResult
      pg(table).select().where('id', '=', tagResult.id).then (rows) ->
        try result = Factory.hydrateAllFrom(table, rows, tagResult.tag); cb result 
        catch e 
          cb {error: 404; message: 'tag not found in ' + table}

  # aka: delete, del
  deleteWithId: (id, cb, tagsCb) ->
    @pg(@table).where('id', '=', id).del().then (rows) -> cb(rows);
    @pg('tags').where('id', '=', id).del().then (rows) -> cb(rows);

  updateWithId: (financeOption, cb) ->
    data = 
      currency: financeOption.money.currency
      amount: financeOption.money.amount
      created_at: financeOption.created_at
      description: financeOption.description

    @pg(@table).where({id: financeOption.id}).update({amount: financeOption.money.amount}).then (rows) -> 
      cb rows

  ### list ###
  list: (cb) -> 
    {pg, table} = {@pg, @table}
    @pg(table).select().then (row) -> return row 
    .map (item) ->
      pg.select().from('tags').where('id', '=', item.id).then (tag) ->
        # because not all tags are in all tables
        return null if tag.length is 0 

        tags = ''
        for i in [0 .. tag.length-1]
          tags += tag[i].tag + ',' 
        tags = tags.substring(0, tags.length - 1) # trim the trailing comma

        fo = Factory.hydrateFrom(table, item, tags)
        return fo
    .then (financialObjects) ->
      cb financialObjects

  ### 
  find the tags 
  using the tag ids
    find the financeOptions 
    send them to a local callback to concat them
      send the result of all concats to the @param callback 

  @TODO: for each one of these financialObjects fetched, get their respective OTHER tags
  @TODO: fix reporting with catching
  ###
  listWithTag: (tag, cb) ->    
    {pg, table} = {@pg, @table}
    @pg.select('id', 'tag').from('tags').where('tag', '=', tag).then (tags) -> return tags
    .map (tag) ->        
      pg.select('tag').from('tags').where('id', '=', tag.id).then (tags) -> return tags
      .then (tags) ->
        pg.select().from(table).where('id', '=', tag.id).then (item) ->
          # because not all tags are in all tables
          return null if item.length is 0 

          try 
            tagString = ''
            for i in [0 .. tags.length-1]
              tagString += tags[i].tag 
              tagString += ',' 
            tagString = tagString.substring(0, tagString.length - 1) # trim the trailing comma
            return Factory.hydrateAllFrom(table, item, tagString)
          catch e
            console.log e.stack
    .filter (financialObject) ->
      return false if financialObject is null 
      return true 
    .then (financialObjects) ->
      financialObjects = _.flatten(financialObjects)
      cb financialObjects



  ### @TODO: cleanup... DRY... ###
  listWithDate: (date, cb) ->
    month = date.getMonth() # on windows, or at least my machine, I have to increment by 1
    year = date.getFullYear()
    query = @pg(@table).select().whereRaw("EXTRACT(MONTH FROM created_at) = " + month).andWhereRaw("EXTRACT(YEAR FROM created_at) = " + year).toString()
    {pg, table} = {@pg, @table}
    @pg.raw(query)
    .then (row) -> return row.rows
    .map (item) ->
      pg.select().from('tags').where('id', '=', item.id).then (tag) -> return tag 
      .then (tag) ->
        tags = ''
        for i in [0 .. tag.length-1]
          tags += tag[i].tag 
          tags += ',' 
        tags = tags.substring(0, tags.length - 1) # trim the trailing comma
        return Factory.hydrateFrom(table, item, tags)

    .then (financialObjects) -> 
      if financialObjects.length is 0
        cb {error: 404; message: table + ' listing using the month and near not found for month: `' + month + '` and year: `' + year + '`'}
      else 
        cb financialObjects

  ### @TODO: should be in another Repo ###
  findTag: (tag, cb) ->
    @pg.select('id', 'tag').from('tag').where({tag: tag}).then (tags) -> cb tags

  findTagsForId: (id, cb) ->
    @pg.select('tag').from('tag').where({id: id}).then (tags) -> cb tags

class IncomeRepository extends FinanceRepository
  table: 'income'
class ExpenseRepository extends FinanceRepository
  table: 'expense'
  

# could find how to use a DIC in nodejs  
# using methods on here for our service enables easy spot for adding caching
# Abstract
class FinanceService 
  constructor: (@repo) ->

  findWithId: (id, callback) -> @repo.findWithId(id, callback)
  save: (financeOption, callback) -> @repo.save(financeOption, callback)

  deleteWithId: (id, callback) -> @repo.deleteWithId(id, callback)
  findBetweenMonths: (monthYearRange, callback) -> @repo.findBetweenMonths(monthYearRange, callback)

  ### 
  if year & month are not defined, set the *current* month and date
  @TODO: combine this with list and add the params with a default of 'infinity' for type? 
  @TODO: remove these defaults and make service skinnier

  @param {string|int: month} month 
  @param {string|int: month} int 
  @param {function} callback 
  ###
  reports: (month, year, callback) ->
    year = new Date().getFullYear() if not year?
    month = new Date().getMonth()+1 if not month?
    # console.log month, year
    return @repo.findWithMonthYear(month, year, callback)

  updateWithId: (financeOption, callback) -> @repo.updateWithId(financeOption, callback)

  listWithDate: (date, callback) -> @repo.listWithDate(date, callback)
  listWithTag: (tag, callback) -> @repo.listWithTag(tag, callback) 
  list: (callback) -> @repo.list(callback)
  existsWithId: (id, callback) -> @repo.existsWithId(id, callback)
  findEarliestDate: (callback) -> @repo.findEarliestDate(callback)
  findLatestDate: (callback) -> @repo.findLatestDate(callback)

class IncomeService extends FinanceService
  constructor: (@repo = new IncomeRepository()) ->

class ExpenseService extends FinanceService
  constructor: (@repo = new ExpenseRepository()) ->


module.exports.FinanceService = FinanceService
module.exports.IncomeService = IncomeService
module.exports.ExpenseService = ExpenseService

module.exports.IncomeRepository = IncomeRepository
module.exports.ExpenseRepository = ExpenseRepository
