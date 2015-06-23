

module.exports = (User, Group) ->

  index: (req, res) ->
    Group.findAll().then (found) ->
      res.json found


  create: (req, res, next) ->
    if not req.body.name
      return res.status(400).send("missing required param: name")
    Group.create(req.body).then (created) ->
      res.status(201).send created
    .catch (err) ->
      res.status(400).send err


  show: (req, res) ->
    # return already found (loaded) host
    res.send(req.group).end()


  update: (req, res) ->
    req.group.updateAttributes(req.body).then () ->
      res.json req.group


  destroy: (req, res) ->
    req.group.destroy().then () ->
      res.json req.group


  # actual object loading function (loads based on req url params)
  load: (id, fn) ->
    Group.find({where: {id: id}}).then (found) ->
      return fn null, found
