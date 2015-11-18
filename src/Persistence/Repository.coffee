_ = require 'underscore'
{dateFromAny} = require('./../Util/dateFrom.coffee')
{Factory} = require('./../FinanceOperation/Boot.coffee')
{MonthYearRange} = require('./../Report/balanceTrend.coffee')

tagArrayToString = (tagRow) ->
  tags = ''
  for i in [0 .. tagRow.length-1]
    tags += tagRow[i].tag + ',' 
  return tags.substring(0, tags.length - 1) # trim the trailing comma

class FinanceRepository
  constructor: (@table) -> 
    @pg = require('./connection.coffee').getPg()

  ### @param {FinanceOperation} or any children (Income or Expense) ###
  save: (financeOperation, cb) ->    
    data = 
      id: financeOperation.id
      # Money, could be split into another table
      currency: financeOperation.money.currency
      amount: financeOperation.money.amount
      # optional
      created_at: financeOperation.created_at
      description: financeOperation.description
    
    @pg
    .insert(data)
    .into(@table).then (rows) -> cb rows

    ### @TODO: optimize & combine the query ###
    tags = financeOperation.tags
    if _.isArray tags
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
    .then ((tag) -> ) #console.log "then" 
    .catch ((e) -> console.log "catch" )

  findWithId: (id, cb) ->
    {pg, table} = {@pg, @table}
    @pg.select().from(@table).where('id', '=', id).then (rows) ->  
      pg.select('tag').from('tags').where('id', '=', id).then (tags) -> 
        tags = _.map tags, (tag) -> tag = tag.tag
        if rows.length is 0 
          cb []
        else 
          try
            cb Factory.hydrateAllFrom table, rows, tags
          catch e
            cb []

  findCreatedAtSortedBy: (sorted, cb) ->
    @pg.select('created_at').from(@table).limit(1).orderBy('created_at', sorted)
    .then (row) -> cb row[0].created_at
  findEarliestDate: (cb) -> @findCreatedAtSortedBy('asc', cb)
  findLatestDate: (cb) -> @findCreatedAtSortedBy('desc', cb)

  findBetweenMonths: (range = new MonthYearRange(), cb) ->
    query = @pg(@table).select()
    .whereRaw("EXTRACT(YEAR FROM created_at) >= " + range.startYear)
    .andWhereRaw("EXTRACT(YEAR FROM created_at) <= " + range.endYear)
    .andWhereRaw("EXTRACT(MONTH FROM created_at) >= " + range.startMonth)
    .andWhereRaw("EXTRACT(MONTH FROM created_at) <= " + range.endMonth)
    .toString()

    {pg, table} = {@pg, @table}
    @pg.raw(query).then (all) -> return all.rows
    .map (item) ->
      pg.select('tag').from('tags').where('id', '=', item.id).then (tagRow) ->
        # because not all tags are in all tables
        return null if tagRow.length is 0
        return Factory.hydrateFrom table, item, tagArrayToString(tagRow)
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
        # return null if tagRow.length is 0 # because not all tags are in all tables 
        return Factory.hydrateFrom table, item, tagArrayToString(tagRow)
    .then (all) ->
      all = _.flatten(all)

      ### @TODO: optimize, don't need to loop 2x ###
      tags = {}

      # getting all the tags from all the items
      for i in [0 .. all.length-1]
        continue if all[i] is undefined 

        tag = all[i].tags

        if _.isArray tag
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
      cb if (rows.length is 0) then false else true

  # aka: delete, del
  deleteWithId: (id, cb, tagsCb) ->
    pg = @pg
    @pg(@table).where('id', '=', id).del().then (result) -> 
      pg('tags').where('id', '=', id).del().then (result) -> 
        cb(result)

  updateWithId: (financeOperation, cb) ->
    data = 
      currency: financeOperation.money.currency
      amount: financeOperation.money.amount
      created_at: financeOperation.created_at
      description: financeOperation.description

    @pg(@table)
    .where({id: financeOperation.id})
    .update({amount: financeOperation.money.amount})
    .then (rows) -> cb rows

  ### list ###
  list: (cb) -> 
    {pg, table} = {@pg, @table}
    @pg(table).select().then (row) -> return row 
    .map (item) ->
      pg.select().from('tags').where('id', '=', item.id).then (tags) ->
        # because not all tags are in all tables
        return null if tags.length is 0 
        return Factory.hydrateFrom table, item, tagArrayToString(tags)
    .then (financialObjects) -> cb financialObjects

  ### 
  find the tags 
  using the tag ids
    find the financeOperations 
    send them to a local callback to concat them
      send the result of all concats to the @param callback 
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
          return Factory.hydrateAllFrom table, item, tagArrayToString(tags)
    .filter (financialObject) ->
      return if (financialObject is null) then false else true
    .then (financialObjects) ->
      financialObjects = _.flatten(financialObjects)
      cb financialObjects


  listWithDate: (date, cb) ->
    month = date.getMonth()+1 # on my machine, I have to increment by 1
    year = date.getFullYear()
    query = @pg(@table).select().whereRaw("EXTRACT(MONTH FROM created_at) = " + month).andWhereRaw("EXTRACT(YEAR FROM created_at) = " + year).toString()
    {pg, table} = {@pg, @table}
    @pg.raw(query)
    .then (row) -> return row.rows 
    .map (item) ->
      pg.select().from('tags').where('id', '=', item.id).then (tag) -> return tag 
      .then (tags) ->
        return Factory.hydrateFrom table, item, tagArrayToString(tags)
    .then (financialObjects) -> 
      cb JSON.stringify(financialObjects)

module.exports.FinanceRepository = FinanceRepository
