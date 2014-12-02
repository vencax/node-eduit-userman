
pwdutils = require('../pwdutils')

module.exports = (db) ->

  userHooks = require('./hooks')(db)  # user hooks

  index: (req, res) ->
    db.User.findAll().then (found) ->
      res.json found

  create: (req, res, next) ->
    if not req.body.username or not req.body.password or not req.body.gid_id
      return res.status(400).send("REQUIRED_PARAM_MISSING")
    req.body.rawpwd = req.body.password
    req.body.password = pwdutils.create_django_hash(req.body.password)
    db.User.create(req.body).then (created) ->
      created.password = null
      res.status(201).send(created).end()
      userHooks.afterCreate(req.body)
    .catch (err) ->
      if err.name == 'SequelizeUniqueConstraintError'
        return res.status(400).send('ALREADY_EXISTS')
      res.status(400).send err
    .done()


  show: (req, res) ->
    req.user.password = null
    # return already found (loaded) host
    res.send(req.user).end()


  update: (req, res) ->
    if req.body.password
      req.user.rawpwd = req.body.password if req.body.password
      req.body.password = pwdutils.create_django_hash(req.body.password)
    req.user.updateAttributes(req.body).then () ->
      res.json req.user
      userHooks.afterUpdate(req.user)


  destroy: (req, res) ->
    req.user.destroy().then () ->
      res.json req.user
      userHooks.afterDestroy(req.user)


  # actual object loading function (loads based on req url params)
  load: (id, fn) ->
    db.User.find({where: {id: id}}).then (found) ->
      return fn null, found
