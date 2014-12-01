

module.exports = (db) ->

  index: (req, res) ->
    db.User.findAll().on 'success', (found) ->
      res.json found


  create: (req, res, next) ->
    if not req.body.username or not req.body.password
      return res.status(400).send("missing required param: name, mac, ip")
    db.User.create(req.body).then (created) ->
      res.status(201).send created
    .catch (err) ->
      res.status(400).send err


  show: (req, res) ->
    # return already found (loaded) host
    res.send(req.user).end()


  update: (req, res) ->
    req.user.updateAttributes(req.body).then () ->
      res.json req.user


  destroy: (req, res) ->
    req.user.destroy().then () ->
      res.json req.user


  # actual object loading function (loads based on req url params)
  load: (id, fn) ->
    db.User.find({where: {id: id}}).then (found) ->
      return fn null, found
