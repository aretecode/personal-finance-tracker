{Factory} = require('./../src/FinanceOperation/Boot.coffee')

expenseRoutes = (app, service) ->
  app.put '/api/expenses/:currency/:amount/:tags/:created_at?/:description?/:id?', (req, res) ->
    p = req.params
    expense = Factory.expense p.id, p.currency, p.amount, p.tags, p.created_at, p.description
    service.save expense, (saved) ->
      res.send saved.code, saved.body

  app.delete '/api/expenses/:id', (req, res) ->
    service.delete req.params.id, (deleted) ->
      # res.status(deleted.code).send deleted.body
      res.send deleted.code, deleted.body

  app.patch '/api/expenses/:id/:currency/:amount/:tags?/:created_at?/:description?', (req, res) -> 
    p = req.params
    expense = Factory.expense p.id, p.currency, p.amount, p.tags, p.created_at, p.description
    service.update expense, (updated) -> 
      res.send updated.code, updated.body

  # deal with this as expenses/:id and have expenses/list
  app.get '/api/expenses/retrieve/:id', (req, res) ->
    service.findWithId req.params.id, (found) -> 
      res.send found.code, found.body

  app.get '/api/expenses/list*', (req, res) ->
    q = req.query
    
    if q.date?
      service.listWithDate q.date, (result) -> 
        res.send result.code, result.body 
    else if q.tag?
      service.listWithTag q.tag, (result) -> 
        res.send result.code, result.body 
    else # default
      service.list (result) -> 
        res.send result.code, result.body  

module.exports.expenseRoutes = expenseRoutes
