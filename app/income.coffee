{Factory} = require('./../src/FinanceOperation/Boot.coffee')

incomeRoutes = (app, service) ->
  app.put '/api/incomes/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) ->
    p = req.params
    income = Factory.income p.id, p.currency, p.amount, p.tags, p.created_at, p.description
    service.save income, (saved) ->
      res.send saved.code, saved.body

  app.delete '/api/incomes/:id', (req, res) ->
    service.delete req.params.id, (deleted) ->
      res.send deleted.code, deleted.body

  app.patch '/api/incomes/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> 
    p = req.params
    income = Factory.income p.id, p.currency, p.amount, p.tags, p.created_at, p.description
    service.update income, (updated) -> 
      res.send updated.code, updated.body

  # deal with this as incomes/:id and have incomes/list
  app.get '/api/incomes/retrieve/:id', (req, res) ->
    service.findWithId req.params.id, (found) -> 
      res.send found.code, found.body

  app.get '/api/incomes/list*', (req, res) ->
    q = req.query
    res.header 'Content-Type', 'application/json'
    if q.date?
      service.listWithDate q.date, (result) -> 
        res.send result.code, result.body 
    else if q.tag?
      service.listWithTag q.tag, (result) -> 
        res.send result.code, result.body 
    else # default
      service.list (result) -> 
        res.send result.code, result.body  

module.exports.incomeRoutes = incomeRoutes
